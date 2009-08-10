#
# = bio/db/phyloxml_parser.rb - PhyloXML parser
#
# Copyright::   Copyright (C) 2009
#               Diana Jaunzeikare <latvianlinuxgirl@gmail.com>
# License::     The Ruby License
#
# $Id:$
#
# == Description
#
# This file containts parser for PhyloXML.
#
# == Requirements
# 
# Libxml2 XML parser is required. Install libxml-ruby bindings from
# http://libxml.rubyforge.org or
#
#   gem install -r libxml-ruby
#
# == References
#
# * http://www.phyloxml.org
#
# * https://www.nescent.org/wg_phyloinformatics/PhyloSoC:PhyloXML_support_in_BioRuby

require 'bio/tree'

require 'bio/db/phyloxml_elements'

require 'xml'

module Bio

module PhyloXML

  # == Description
  #
  # Bio::PhyloXML is for parsing phyloXML format files.
  # This is an alpha version. Incompatible changes may be made frequently.
  #
  # == Requirements
  #
  # Libxml2 XML parser is required. Install libxml-ruby bindings from
  # http://libxml.rubyforge.org or
  #
  #   gem install -r libxml-ruby
  #
  # == Usage
  #
  #   require 'bio'
  #
  #  # Create new phyloxml parser
  #  phyloxml = Bio::PhyloXML::Parser.new('example.xml')
  #
  #  # Print the names of all trees in the file
  #  phyloxml.each do |tree|
  #    puts tree.name
  #  end
  #
  #
  # == References
  #
  # http://www.phyloxml.org/documentation/version_100/phyloxml.xsd.html
  #
  class Parser

    #
    # After parsing all the trees, if there is anything else in other xml format,
    # it is saved in this array.
    attr_reader :other

    # Initializes LibXML::Reader and reads the file until it reaches the first
    # phylogeny element.
    #
    # Create a new Bio::PhyloXML object.
    #
    #   p = Bio::PhyloXML.new("./phyloxml_examples.xml")
    #
    # ---
    # *Arguments*:
    # * (required) _filename_: Path to the file to parse.
    # *Returns*:: Bio::PhyloXML::Parser object
    def initialize(filename)

      @other = []
      #@todo decide if need to be able initialize using string, since usually xml lives in files

      #check if parameter is a valid file name
      if File.exists?(filename)
        schema = XML::Schema.document(XML::Document.file(File.join(File.dirname(__FILE__),'phyloxml.xsd')))
        xml_instance = XML::Document.file(filename)
        xml_instance.validate_schema(schema) do |msg, flag|
          puts msg
          raise "Validation of the XML document against phyloxml.xsd schema failed." + msg
        end        

        @reader = XML::Reader.file(filename)
      else 
        #assume it is string input
        @reader = XML::Reader.string(filename)
      end

      #loops through until reaches phylogeny stuff
      # Have to leave this way, if accepting strings, instead of files
      @reader.read until is_element?('phylogeny')
    end

    # Iterate through all trees in the file.
    #
    #  phyloxml = Bio::PhyloXML::Parser.new('example.xml')
    #  phyloxml.each do |tree|
    #    puts tree.name
    #  end
    #
    def each
      while tree = next_tree
        yield tree
      end
    end

    # Access the specified tree in the file. It parses trees until the specified
    # tree is reached.
    #
    #  # Get 3rd tree in the file (starts counting from 0).
    #  parser = PhyloXML::Parser.new('phyloxml_examples.xml')
    #  tree = parser[2]
    #
    def [](i)
      tree = nil
      (i+1).times do
       tree =  self.next_tree
      end
      return tree
    end

    # Parse and return the next phylogeny tree.
    # 
    #  p = Bio::PhyloXML::Parser.new("./phyloxml_examples.xml")
    #  tree = p.next_tree
    #
    # ---
    # *Returns*:: Bio::PhyloXML::Tree
    def next_tree()

      if not is_element?('phylogeny')
        if @reader.node_type == XML::Reader::TYPE_END_ELEMENT
          if is_end_element?('phyloxml')
            return nil
          else
            @reader.read
            @reader.read
            if is_end_element?('phyloxml')
              return nil
            end
          end
        end        
        # phyloxml can hold only phylogeny and "other" elements. If this is not
        # phylogeny element then it is other. Also, "other" always comes after
        # all phylogenies
        #@other = parse_other
        #puts "===================  Other parsed: "
        #p @other
        #return @other
        @other << parse_other
        #p o
        return nil
        
         #return nil for tree, since this is not valid phyloxml tree.
        #@todo maybe not, maybe return a tree of Other object elements.
        #Lets return other object too, then it will also be easier to write all the trees back to file
      elsif is_end_element?('phyloxml')
        puts "end"
      end

      tree = Bio::PhyloXML::Tree.new

      # keep track of current node in clades array/stack. Current node is the
      # last element in the clades array
      clades = []
      clades.push tree
      
      #keep track of current edge to be able to parse branch_length tag
      current_edge = nil

      # we are going to parse clade iteratively by pointing (and changing) to
      # the current node in the tree. Since the property element is both in
      # clade and in the phylogeny, we need some boolean to know if we are
      # parsing the clade (there can be only max 1 clade in phylogeny) or
      # parsing phylogeny
      parsing_clade = false

      while not is_end_element?('phylogeny') do
        break if is_end_element?('phyloxml')
        
        # parse phylogeny elements, except clade
        if not parsing_clade

          # @todo when entering in next_tree, first element should be phylogeny,
          # so it should not be checked here.
          if is_element?('phylogeny')
            @reader["rooted"] == "true" ? tree.rooted = true : tree.rooted = false
            @reader["rerootable"] == "true" ? tree.rerootable = true : tree.rerootable = false
            parse_attributes(tree, ["branch_length_unit", 'type'])
          end

          parse_simple_elements(tree, [ "name", 'description', "date"])

          if is_element?('confidence')
            tree.confidences << parse_confidence
          end

        end

        if @reader.node_type == XML::Reader::TYPE_ELEMENT
          case @reader.name
          when 'clade'
            #parse clade element

            parsing_clade = true

            node= Bio::PhyloXML::Node.new

            branch_length = @reader['branch_length']

            parse_attributes(node, ["id_source"])

            #add new node to the tree
            tree.add_node(node)
            # The first clade will always be root since by xsd schema phyloxml can
            # have 0 to 1 clades in it.
            if tree.root == nil
              tree.root = node
            else
              current_edge = tree.add_edge(clades[-1], node,
                                           Bio::Tree::Edge.new(branch_length))
            end
            clades.push node
            #end if clade element
          else
           parse_clade_elements(clades[-1], current_edge) if parsing_clade
          end
        end

        #end clade element, go one parent up
        if is_end_element?('clade')

           #if we have reached the closing tag of the top-most clade, then our
          # curent node should point to the root, If thats the case, we are done
          # parsing the clade element
          if clades[-1] == tree.root
            parsing_clade = false
          else
            # set current node to the previous clade in the array
            clades.pop
          end
        end          

        #parsing phylogeny elements
        if not parsing_clade

          if @reader.node_type == XML::Reader::TYPE_ELEMENT
            case @reader.name
            when 'property'
              tree.properties << parse_property
            when 'clade_relation'
              clade_relation = CladeRelation.new
              parse_attributes(clade_relation, ["id_ref_0", "id_ref_1", "distance", "type"])

              #@ add unit test for this
              if not @reader.empty_element?
                @reader.read
                if is_element?('confidence')
                  clade_relation.confidence = parse_confidence
                end
              end
              tree.clade_relations << clade_relation

            when 'sequence_relation'
              sequence_relation = SequenceRelation.new
              parse_attributes(sequence_relation, ["id_ref_0", "id_ref_1", "distance", "type"])
              if not @reader.empty_element?
                @reader.read
                if is_element?('confidence')
                  sequence_relation.confidence = parse_confidence
                end
              end
              tree.sequence_relations << sequence_relation
            when 'phylogeny'
              #do nothing
            else
              puts "Not recognized element. #{@reader.name}"
            end
          end

#          if is_element?('property')
#            tree.properties << parse_property
#          end
#
#          if is_element?('clade_relation')
#            clade_relation = CladeRelation.new
#            parse_attributes(clade_relation, ["id_ref_0", "id_ref_1", "distance", "type"])
#
#            #@ add unit test for this
#            if not @reader.empty_element?
#              @reader.read
#              if is_element?('confidence')
#                clade_relation.confidence = parse_confidence
#              end
#            end
#            tree.clade_relations << clade_relation
#          end
#
#          if is_element?('sequence_relation')
#
#            sequence_relation = SequenceRelation.new
#            parse_attributes(sequence_relation, ["id_ref_0", "id_ref_1", "distance", "type"])
#
#
#            if not @reader.empty_element?
#              @reader.read
#              if is_element?('confidence')
#                sequence_relation.confidence = parse_confidence
#              end
#            end
#            tree.sequence_relations << sequence_relation
#          end

        end
        # go to next element        
        @reader.read    
      end #end while not </phylogeny>
      #move on to the next tag after /phylogeny which is text, since phylogeny
      #end tag is empty element, which value is nil, therefore need to move to
      #the next meaningful element (therefore @reader.read twice)
      @reader.read 
      @reader.read

      return tree
    end  

    # return tree of specified name.
    # @todo Implement this method. 
    # def get_tree_by_name(name)

#      while not is_end_element?('phyloxml')
#        if is_element?('phylogeny')
#          @reader.read
#          @reader.read
#
#          if is_element?('name')
#            @reader.read
#            if @reader.value == name
#              puts "equasl"
#              tree = next_tree
#              puts tree
#            end
#          end
#        end
#        @reader.read
#      end
#
  #  end


    private

    ####
    # Utility methods
    ###

    def is_element?(str)
      @reader.node_type == XML::Reader::TYPE_ELEMENT and @reader.name == str ? true : false
    end

    def is_end_element?(str)
      @reader.node_type==XML::Reader::TYPE_END_ELEMENT and @reader.name == str ? true : false
    end

    def has_reached_end_element?(str)
      if not(is_end_element?(str))
        #puts "Warning: Should have reached </#{str}> element here"
        raise "Warning: Should have reached </#{str}> element here"
      end
    end

    # Parses a simple XML element. for example <speciations>1</speciations>
    # It reads in the value and assigns it to object.speciation = 1
    # Also checks if have reached end tag (</speciations> and gives warning
    # if not
    def parse_simple_element(object, name)
      if is_element?(name)
        @reader.read
        object.send("#{name}=", @reader.value)
        @reader.read
        has_reached_end_element?(name)
      end
    end

    def parse_simple_elements(object, elements)
      elements.each do |elmt|
          parse_simple_element(object, elmt)
      end      
    end

    #Parses list of attributes
    #use for the code like: clade_relation.type = @reader["type"]
    def parse_attributes(object, arr_of_attrs)
      arr_of_attrs.each do |attr|
        object.send("#{attr}=", @reader[attr])
      end
    end

    #parses elements where attributes of the object are arrays of objects.
    def parse_complex_array_elements(object, elements)
      #@todo this code might not be needed anymore. (Does not work with plural forms)
      # Example code:
      # if is_element('confidence')
      #   current_node.confidence << parse_confidence
      # end
      elements.each do |elem|        
        if is_element?(elem)
          object.send("#{elem}") << self.send("parse_#{elem}")
        end
      end
    end #parse_complex_array_elements

    def parse_clade_elements(current_node, current_edge)
      #no loop inside, it is already outside

      if @reader.node_type == XML::Reader::TYPE_ELEMENT
        case @reader.name
        when 'branch_length'
          # @todo add unit test for this. current_edge is nil, if the root clade
          # has branch_length attribute. Is it even supposed to have? Its still
          # valid xml.
          @reader.read
          branch_length = @reader.value
          current_edge.distance = branch_length.to_f if current_edge != nil
          @reader.read
        when 'width'
          @reader.read
          current_node.width = @reader.value
          @reader.read
        when  'name'
          @reader.read
          current_node.name = @reader.value
          @reader.read
        when 'events'
          current_node.events = parse_events
        when 'confidence'
          current_node.confidences << parse_confidence
        when 'sequence'
          current_node.sequences << parse_sequence
        when 'property'
          current_node.properties << parse_property
        when 'taxonomy'
          current_node.taxonomies << parse_taxonomy
        when 'distribution'
          current_node.distributions << parse_distribution
        when 'node_id'
          id = Id.new
          id.type = @reader["type"]
          @reader.read
          id.value = @reader.value
          @reader.read
          #has_reached_end_element?('node_id')
          #@todo write unit test for this. There is no example of this in the example files
          current_node.id = id
        when 'color'
          color = BranchColor.new
          parse_simple_element(color, 'red')
          parse_simple_element(color, 'green')
          parse_simple_element(color, 'blue')
          current_node.color = color
          #@todo add unit test for this
        when 'date'
          date = Date.new
          date.unit = @reader["unit"]
          #parse_attributes(date, ["unit"])

          #move to the next token, which is always empty, since date tag does not
          # have text associated with it
          @reader.read
          @reader.read #now the token is the first tag under date tag
          while not(is_end_element?('date'))
            parse_simple_element(date, 'desc')
            parse_simple_element(date, 'value')
            parse_simple_element(date, 'minimum')
            parse_simple_element(date, 'maximum')
            @reader.read
          end
          current_node.date = date
        when 'reference'
          reference = Reference.new()
          reference.doi = @reader['doi']
          if not @reader.empty_element?
            while not is_end_element?('reference')
              parse_simple_element(reference, 'desc')
              @reader.read
            end
          end
          current_node.references << reference
        when 'binary_characters'
          current_node.binary_characters  = parse_binary_characters
        when 'clade'
          #do nothing
        else
          #do nothing now
          puts "No match found in parse_clade_elements.(#{@reader.name})"
        end

      end

    end #parse_clade_elements

    def parse_events()
      events = PhyloXML::Events.new
      @reader.read #go to next element
      while not(is_end_element?('events')) do
        parse_simple_elements(events, ['type', 'duplications',
                                            'speciations', 'losses'])
        if is_element?('confidence')
          events.confidence = parse_confidence
          #@todo add unit test for this (example file does not have this case)
        end
        @reader.read
      end
      return events
    end #parse_events

    def parse_taxonomy
      taxonomy = PhyloXML::Taxonomy.new
      parse_attributes(taxonomy, ["id_source"])
      @reader.read
      while not(is_end_element?('taxonomy')) do

        #parse_simple_elements(taxonomy,['code', 'scientific_name', 'rank', 'authority'] )

        if @reader.node_type == XML::Reader::TYPE_ELEMENT
          case @reader.name
          when 'code'
            @reader.read
            taxonomy.code = @reader.value
            @reader.read
          when 'scientific_name'
            @reader.read
            taxonomy.scientific_name = @reader.value
            @reader.read
          when 'rank'
            @reader.read
            taxonomy.rank = @reader.value
            @reader.read
          when 'authority'
            @reader.read
            taxonomy.authority = @reader.value
            @reader.read
          when 'id'
            taxonomy.taxonomy_id = parse_id('id')
          when 'common_name'
            @reader.read
            taxonomy.common_names << @reader.value
            @reader.read
            #has_reached_end_element?('common_name')
          when 'synonym'
            @reader.read
            taxonomy.synonyms << @reader.value
            @reader.read
            #has_reached_end_element?('synonym')
          else
            taxonomy.uri = parse_uri
          end
        end

#        taxonomy.taxonomy_id = parse_id('id') if is_element?('id')
#
#        if is_element?('common_name')
#          @reader.read
#          taxonomy.common_names << @reader.value
#          @reader.read
#          has_reached_end_element?('common_name')
#        end
#
#        if is_element?('synonym')
#          @reader.read
#          taxonomy.synonyms << @reader.value
#          @reader.read
#          has_reached_end_element?('synonym')
#        end
#
#        taxonomy.uri = parse_uri if is_element?('uri')

        @reader.read  #move to next tag in the loop
      end
      return taxonomy
    end #parse_taxonomy

    private

    def parse_sequence
      sequence = Sequence.new
      parse_attributes(sequence, ["type", "id_source", "id_ref"])
      
      @reader.read
      while not(is_end_element?('sequence'))

        parse_simple_elements(sequence,['symbol', 'name', 'location', 'symbol'])

        if is_element?('mol_seq')
          sequence.is_aligned = @reader["is_aligned"]
          @reader.read          
          sequence.mol_seq = @reader.value
          @reader.read
          has_reached_end_element?('mol_seq')
        end


        if is_element?('accession')
          sequence.accession = Accession.new
          sequence.accession.source = @reader["source"]
          @reader.read
          sequence.accession.value = @reader.value
          @reader.read
          has_reached_end_element?('accession')
        end

        sequence.uri = parse_uri if is_element?('uri')

        sequence.annotations << parse_annotation if is_element?('annotation')

        if is_element?('domain_architecture')
          sequence.domain_architecture = DomainArchitecture.new
          sequence.domain_architecture.length = @reader["length"]

          @reader.read
          @reader.read          
          while not(is_end_element?('domain_architecture'))
            sequence.domain_architecture.domains << parse_domain
            @reader.read #go to next domain element
          end
        end
        
        @reader.read
      end
      return sequence
    end #parse_sequence

    def parse_uri
      uri = Uri.new
      parse_attributes(uri, ["desc", "type"])
      parse_simple_element(uri, 'uri')
      return uri
    end

    def parse_annotation
      annotation = Annotation.new

      parse_attributes(annotation, ['ref', 'source', 'evidence', 'type'])

      if not @reader.empty_element?
        while not(is_end_element?('annotation'))
          parse_simple_element(annotation, 'desc') if is_element?('desc')

          annotation.confidence  = parse_confidence if is_element?('confidence')

          annotation.properties << parse_property if is_element?('property')

          if is_element?('uri')
            annotation.uri = parse_uri
            #@todo add unit test to this
          end

          @reader.read
        end
        
      end
      return annotation
    end

    def parse_property
      property = Property.new
      parse_attributes(property, ["ref", "unit", "datatype", "applies_to", "id_ref"])
      @reader.read
      property.value = @reader.value
      @reader.read
      has_reached_end_element?('property')     
      return property
    end #parse_property

    def parse_confidence
      type = @reader["type"]
      @reader.read
      value = @reader.value.to_f
      @reader.read
      has_reached_end_element?('confidence')
      return Confidence.new(type, value)
    end #parse_confidence

    def parse_distribution
      distribution = Distribution.new
      @reader.read
      while not(is_end_element?('distribution')) do

        parse_simple_element(distribution, 'desc')

        distribution.points << parse_point if is_element?('point')
        distribution.polygons << parse_polygon if is_element?('polygon')

        @reader.read
      end
      return distribution
    end #parse_distribution

    def parse_point
      point = Point.new

      point.geodetic_datum = @reader["geodetic_datum"]
      point.alt_unit = @reader["alt_unit"]

      @reader.read
      while not(is_end_element?('point')) do

        parse_simple_elements(point, ['lat', 'long'] )

        if is_element?('alt')
          @reader.read
          point.alt = @reader.value.to_f
          @reader.read
          has_reached_end_element?('alt')
        end
        #advance reader
        @reader.read
      end
      return point
    end #parse_point

    def parse_polygon
      polygon = Polygon.new
      @reader.read
      while not(is_end_element?('polygon')) do
        polygon.points << parse_point if is_element?('point')
        @reader.read
      end

      #@should check for it at all? Probably not if xml is valid. 
      if polygon.points.length <3
        puts "Warning: <polygon> should have at least 3 points"
      end
      return polygon
    end #parse_polygon

    def parse_id(tag_name)
      id = Id.new
      id.provider = @reader["provider"]
      @reader.read
      id.value = @reader.value
      @reader.read #@todo shouldn't there be another read?
      has_reached_end_element?(tag_name)
          #@todo write unit test for this. There is no example of this in the example files
      return id
    end #parse_id

    def parse_domain
      domain = ProteinDomain.new
      parse_attributes(domain, ["from", "to", "confidence", "id"])
      @reader.read
      domain.value = @reader.value
      @reader.read
      has_reached_end_element?('domain')
      @reader.read
      return domain
    end

    def parse_binary_characters
      b = PhyloXML::BinaryCharacters.new
      b.bc_type = @reader['type']

      #parse_attributes(b, ['type', 'gained_count', 'absent_count', 'lost_count', 'present_count'])
      parse_attributes(b, ['gained_count', 'absent_count', 'lost_count', 'present_count'])
      if not @reader.empty_element?
        @reader.read
        while not is_end_element?('binary_characters')

          parse_bc(b, 'lost')
          parse_bc(b, 'gained')
          parse_bc(b, 'absent')
          parse_bc(b, 'present')

          @reader.read
        end
      end
      return b
    end #parse_binary_characters

    def parse_bc(object, element)
      if is_element?(element)
        @reader.read
        while not is_end_element?(element)
          if is_element?('bc')
            @reader.read
            object.send(element) << @reader.value
            @reader.read
            has_reached_end_element?('bc')
          end
        @reader.read
        end
      end
    end #parse_bc

    def parse_other
      other_obj = PhyloXML::Other.new
      other_obj.element_name = @reader.name
      #parse attributes
      code = @reader.move_to_first_attribute
      while code ==1
        other_obj.attributes[@reader.name] = @reader.value
        code = @reader.move_to_next_attribute        
      end

      while not is_end_element?(other_obj.element_name) do
        @reader.read
        if @reader.node_type == XML::Reader::TYPE_ELEMENT
           other_obj.children << parse_other #recursice call to parse children
        elsif @reader.node_type == XML::Reader::TYPE_TEXT
          other_obj.value = @reader.value
        end
      end
      #just a check
      has_reached_end_element?(other_obj.element_name)
      return other_obj
    end #parse_other

  end #class phyloxmlParser

end #module PhyloXML
  
end #module Bio
