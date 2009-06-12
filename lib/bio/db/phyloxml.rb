#
# = bio/io/phyloxml.rb - PhyloXML tree parser 
#
# Copyright::   Copyright (C) 2009
#               Diana Jaunzeikare <latvianlinuxgirl@gmail.com>
# License::     The Ruby License
#
# $Id:$
#
# == Description
#
# This file containts parser for PhyloXML
#
# == References
#
# * http://www.phyloxml.org

require 'bio/tree'
require 'xml'

$debug = false

module Bio


  class PhyloXMLTree < Bio::Tree
  
    attr_accessor :name, :description, :rooted, :property,
      :clade_relation, :sequence_relation
 
  end

  #+++
  # PhyloXMLNode class
  #+++

  # Class to hold clade element of phyloXML.
  class PhyloXMLNode 
    
    #Events at the root node of a clade (e.g. one gene duplication).
    attr_accessor :events

    attr_accessor :id_source, :name
      
    attr_reader :width

    def width=(str)
      @width = str.to_f
    end

    attr_accessor :taxonomy

    #A general purpose confidence element. For example this can be used to express the bootstrap support value of a clade (in which case the 'type' attribute is 'bootstrap').
    attr_accessor :confidence

    attr_accessor :color 

    attr_accessor :node_id 

    #Element Sequence is used to represent a molecular sequence (Protein, DNA,
    # RNA) associated with a node. 'symbol' is a short (maximal ten characters)
    # symbol of the sequence (e.g. 'ACTM') whereas 'name' is used for the full
    # name (e.g. 'muscle Actin'). 'location' is used for the location of a
    # sequence on a genome/chromosome. The actual sequence can be stored with
    # the 'mol_seq' element. Attribute 'type' is used to indicate the type
    # of sequence ('dna', 'rna', or 'aa'). One intended use for 'id_ref' is
    # to link a sequence to a taxonomy (via the taxonomy's 'id_source') in
    # case of multiple sequences and taxonomies per node.
    attr_accessor :sequence

    attr_accessor :binary_characters #@todo design class for this

    #The geographic distribution of the items of a clade (species, sequences),
    #intended for phylogeographic applications. The location can be described
    #either by free text in the 'desc' element and/or by the coordinates of one
    #or more 'Points' (similar to the 'Point' element in Google's KML format)
    #or by 'Polygons'.
    attr_accessor :distribution

    #A date associated with a clade/node. Its value can be numerical by using
    #the 'value' element and/or free text with the 'desc' element'
    #(e.g. 'Silurian'). If a numerical value is used, it is recommended to
    #employ the 'unit' attribute to indicate the type of the numerical value
    #(e.g. 'mya' for 'million years ago').
    attr_accessor :date
    
    #Array of references
    attr_accessor :reference

    #An array of properties, for example depth for sea animals.
    attr_accessor :property

    def initialize      
      @confidence = []
      @sequence = []
      @taxonomy = []
      @distribution = []
      @reference = []
      @property = []
    end
    

  end

  #+++
  # Events class
  #+++

  #Events at the root node of a clade (e.g. one gene duplication).
  class Events
    #value comes from list: {'transfer'|'fusion'|'speciation_or_duplication'|'other'|'mixed'|'unassigned'}
    attr_accessor :type
    attr_reader :duplications
    attr_reader :speciations
    attr_reader :losses
    attr_reader :confidence

    def confidence=(type, value)
      @confidence = Confidence.new(type, value)
    end

    def confidence=(conf)
      @confidence = conf
    end

    def duplications=(str)
      @duplications = str.to_i
    end

    def losses=(str)
      @losses = str.to_i
    end

    def speciations=(str)
      @speciations=str.to_i
    end

    def type=(str)
      @type = str
      #@todo add unit test for this
      if not ['transfer','fusion','speciation_or_duplication','other','mixed','unassigned'].include?(str)
        puts "Warning #{str} is not one of the allowed values"
      end
    end
  end

  #+++
  # Taxonomy class
  #+++

  # This is general Taxonomy class.
  class Taxonomy
    #pattern = [a-zA-Z0-9_]{2,10} Swiss-prot specific in phyloXML case
    attr_accessor :code

    attr_accessor :scientific_name
    #An array of strings
    attr_accessor :common_name
    # value comes from list: {'domain'|'kingdom'|'subkingdom'|'branch'|'infrakingdom'|'superphylum'|'phylum'|'subphylum'|'infraphylum'|'microphylum'|'superdivision'|'division'|'subdivision'|'infradivision'|'superclass'|'class'|'subclass'|'infraclass'|'superlegion'|'legion'|'sublegion'|'infralegion'|'supercohort'|'cohort'|'subcohort'|'infracohort'|'superorder'|'order'|'suborder'|'superfamily'|'family'|'subfamily'|'supertribe'|'tribe'|'subtribe'|'infratribe'|'genus'|'subgenus'|'superspecies'|'species'|'subspecies'|'variety'|'subvariety'|'form'|'subform'|'cultivar'|'unknown'|'other'}
    attr_accessor :rank

    def inspect
      #@todo work on this / or throw it out. was used for testing.
      print "Taxonomy. scientific_name: #{@scientific_name}\n"
    end

    def initialize
      @common_name = []
    end
  end

  
  #+++
  # PhyloXMLTaxonomy class
  #+++

  # Element 'id' is used for a unique identifier of a taxon (for example '6500'
  # with 'ncbi_taxonomy' as 'type' for the California sea hare). Attribute
  # 'id_source' is used to link other elements to a taxonomy (on the xml-level).
  class PhyloXMLTaxonomy < Taxonomy
    attr_accessor :id
    attr_accessor :id_source
    attr_accessor :type
    attr_accessor :uri
  end

  #+++
  # Confidence class
  #+++

  # A general purpose confidence element. For example this can be used to express
  # the bootstrap support value of a clade (in which case the 'type' attribute
  # is 'bootstrap').
  class Confidence
    attr_accessor :type
    attr_accessor :value

    def initialize(type, value)
      @type = type
      @value = value
    end

  end

  #+++
  # Distribution class
  #+++

  # The geographic distribution of the items of a clade (species, sequences), 
  # intended for phylogeographic applications. The location can be described 
  # either by free text in the 'desc' element and/or by the coordinates of 
  # one or more 'Points' (similar to the 'Point' element in Google's KML 
  # format) or by 'Polygons'.
  class Distribution
    #String
    attr_accessor :desc
    #Array of Point objects
    attr_accessor :points

    attr_accessor :polygons 

    def initialize
      @points = []
      @pplygons = []
    end
  end #Distribution class

  #+++
  # Point class
  #+++

  class Point
    attr_accessor :lat, :long, :alt, :geodetic_datum

    def initialize
      @alt = []
    end

    def lat=(str)
      @lat = str.to_f
    end

    def long=(str)
      @long = str.to_f
    end
    
  end

  class Polygon
    attr_accessor :points

    def initialize
      @points = []
    end
  end
  
  class Sequence
    #values from rna, dna, aa
    attr_accessor :type    
    attr_accessor :id_source
    attr_accessor :id_ref
    attr_accessor :symbol
    attr_accessor :accession
    attr_accessor :name
    #location of a sequence on a genome/chromosome
    attr_accessor :location
    attr_accessor :mol_seq
    attr_accessor :uri #@todo alias method url ?
    attr_accessor :annotation
    attr_accessor :domain_architecture
    
    def initialize
      @annotation = []
    end    
   
  end

  class Accession
    #Example: "UniProtKB"
    attr_accessor :source
    
    #Example: "P17304"
    attr_accessor :value #@todo maybe call it id. 
  end

  class Uri
    attr_accessor :desc
    attr_accessor :type
    attr_accessor :uri #@todo call it url?
  end

  class Annotation
    attr_accessor :ref
    attr_accessor :source
    attr_accessor :evidence
    attr_accessor :type
    attr_accessor :desc
    attr_accessor :confidence
    attr_accessor :property
    attr_accessor :uri

    def initialize
      @property = []
    end
  end

  class Id
    attr_accessor :type, :value
  end

  class BranchColor
    attr_accessor :red, :green, :blue
  end

  class Date
    attr_accessor :unit,  :desc

    attr_reader :range, :value

    def to_s
      return "#{value} #{unit}"
    end

    def range=(str)
      @range = str.to_i
    end

    def value= (str)
      @value = str.to_i
    end
  end

  class DomainArchitecture
    attr_accessor :length
    attr_reader :domain

    def initialize
      @domain = []
    end
  end

  #To represent an individual domain in a domain architecture. The name/unique identifier is described via the 'id' attribute. 'confidence' can be used to store (i.e.) E-values.
  class ProteinDomain
    #simple string, for example to store E-values
    attr_accessor :confidence
    
    #strings
    attr_accessor :id, :value

    attr_reader :from, :to

    def from=(str)
      @from = str.to_i
    end

    def to=(str)
      @to = str.to_i
    end

  end

  #Property allows for typed and referenced properties from external resources
  #to be attached to 'Phylogeny', 'Clade', and 'Annotation'. The value of a
  #property is its mixed (free text) content. Attribute 'datatype' indicates
  #the type of a property and is limited to xsd-datatypes (e.g. 'xsd:string',
  #'xsd:boolean', 'xsd:integer', 'xsd:decimal', 'xsd:float', 'xsd:double',
  #'xsd:date', 'xsd:anyURI'). Attribute 'applies_to' indicates the item to
  #which a property applies to (e.g. 'node' for the parent node of a clade,
  #'parent_branch' for the parent branch of a clade). Attribute 'id_ref' allows
  #to attached a property specifically to one element (on the xml-level).
  #Optional attribute 'unit' is used to indicate the unit of the property.
  #An example: <property datatype="xsd:integer" ref="NOAA:depth" applies_to="clade" unit="METRIC:m"> 200 </property>
  class Property
    attr_accessor :ref, :unit, :id_ref, :value
    
    attr_reader :datatype, :applies_to

    def datatype=(str)
      unless ['xsd:string','xsd:boolean','xsd:decimal','xsd:float','xsd:double',
          'xsd:duration','xsd:dateTime','xsd:time','xsd:date','xsd:gYearMonth',
          'xsd:gYear','xsd:gMonthDay','xsd:gDay','xsd:gMonth','xsd:hexBinary',
          'xsd:base64Binary','xsd:anyURI','xsd:normalizedString','xsd:token',
          'xsd:integer','xsd:nonPositiveInteger','xsd:negativeInteger',
          'xsd:long','xsd:int','xsd:short','xsd:byte','xsd:nonNegativeInteger',
          'xsd:unsignedLong','xsd:unsignedInt','xsd:unsignedShort',
          'xsd:unsignedByte','xsd:positiveInteger'].include?(str)
        puts "Warning: #{str} is not in the list of allowed values."
      end
      #@todo add unit test
      @datatype = str
    end

    def applies_to=(str)
      unless ['phylogeny','clade','node','annotation','parent_branch','other'].include?(str)
        puts "Warning: #{str} is not in the list of allowed values."
      end
      @applies_to = str
    end
  end

  #+++
  # Reference class
  #+++

  #A literature reference for a clade. It is recommended to use the 'doi'
  #attribute instead of the free text 'desc' element whenever possible.
  class Reference
    attr_accessor :doi, :desc
  end

  #+++
  # Clade Relation class
  #+++

  class CladeRelation
    attr_accessor :distance, :type, :confidence
    attr_accessor :id_ref_0, :id_ref_1
  end


  class SequenceRelation
    attr_accessor :id_ref_0, :id_ref_1, :distance, :type
  end

  #---
  # PhyloXML parser
  #+++

  # PhyloXML standard phylogenetic tree parser class.
  #
  # This is alpha version. Incompatible changes may be made frequently.
  class PhyloXML

    def initialize(str) 
      #@note there might be a better way how to do this
      #check if parameter is a valid file name
      if File.exists?(str) 
        @reader = XML::Reader.file(str)
      else 
        #assume it is string input
        @reader = XML::Reader.string(str)
      end
      #@todo should loop through until reaches phylogeny stuff
      while not is_element?('phylogeny')
        @reader.read
        #puts @reader.name
      end
    end
    
    def file(filename)
      @reader = XML::Reader.file(filename)

    end
    
    def next_tree()

      #@todo change it to have many clade_relations

      #@todo what about a method for skipping a tree. (might save on time by not creating all those objects)

      if not is_element?('phylogeny')
        print "Warning: This should have been phylogeny element, but it is: ", @reader.name, " ", @reader.value, "\n"

        #@todo deal with rest of the stuff, maybe read in as text and add it to PhyloXML
        #@todo what if there are phylogeny elements after the extra stuff
        #for now ignore the rest of the stuff
        #and loop until the next phylogeny element if there is one, in case 
        #there are more phylogeny elements after other stuff, so that next read 
        #is successful
        while is_element?('phylogeny') or is_end_element?('phyloxml')
          @reader.read
        end
        return nil
      end

      tree = Bio::PhyloXMLTree.new()

      #current_node variable is a pointer to the current node parsed
      current_node = tree
      
      #keep track of current edge to be able to parse branch_length tag
      current_edge = nil

      #we are going to parse clade iteratively by pointing (and changing) to the
      # current node in the tree. Since the property element is both in clade
      # and in the phylogeny, we need some boolean to know if we are
      # parsing the clade (there can be only max 1 clade in phylogeny) or
      # parsing phylogeny
      parsing_clade = false

      while not is_end_element?('phylogeny') do

         #do the stuff what pertains to the tree
        if not parsing_clade

          if is_element?('phylogeny')
            @reader["rooted"] == "true" ? tree.rooted = true : tree.rooted = false
          end

          #parse elements
          parse_simple_element(tree, 'name')
          parse_simple_element(tree, 'description')

          if is_element?('confidence')
            tree.confidence << parse_confidence
            #@todo add unit test for this
          end

        end



        #clade element
        if is_element?('clade')
          parsing_clade = true #@todo when to set it to false? when current_node points to the root.
          #create a new node
          node= Bio::PhyloXMLNode.new
          
          #parse attributes of the clade element
          branch_length = @reader['branch_length']

          parse_attributes(node, ["id_source"])
          

          #add new node to the tree
                  
          # The first clade will always be root since by xsd schema phyloxml can have 0..1 clades in it.
          if tree.root == nil
            tree.root = node
          else                    
            tree.add_node(node)
            current_edge = tree.add_edge(current_node, node, Bio::Tree::Edge.new(branch_length))
          end
          current_node = node          
        end #end if clade  
    
        #end clade element, go one parent up
        if is_end_element?('clade')
        #  puts current_node.name
          current_node = tree.parent(current_node)
          #if we have reached the closing tag of the top-most clade, then our
          # curent node should point to the root, If thats the case, we are done
          # parsing the clade element          
          if current_node == tree.root
            #puts "Have reached root"
            parsing_clade = false
          end
        end          

        #parsing clade elements
        parse_clade_elements(current_node, current_edge) if parsing_clade

        #parsing phylogeny elements
        if not parsing_clade
          if is_element?('property')
            tree.property = parse_property
          end
          #@todo add unit test for this

          if is_element?('clade_relation')
            tree.clade_relation = CladeRelation.new

            parse_attributes(tree.clade_relation, ["id_ref_0", "id_ref_1", "distance", "type"])

            #@todo add unit test for this
            if not @reader.empty_element?
              @reader.read
              if is_element?('confidence')
                tree.clade_relation.confidence = parse_confidence
              end
            end
          end
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
        puts "Warning: Should have reached </#{str}> element here"
      end
    end

    # Parses a simple XML element. for example <speciations>1</speciations>
    # It reads in the value and assigns it to object.speciation = 1
    # Also checks if have reached end tag (</speciations> and gives warning if not
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
    #use for the code like: tree.clade_relation.type = @reader["type"]
    def parse_attributes(object, arr_of_attrs)
      arr_of_attrs.each do |attr|
        object.send("#{attr}=", @reader[attr])
      end
    end


    #parses elements where attributes of the object are arrays of objects.
    #@todo maybe there is better name for this method
    def parse_complex_array_elements(object, elements)
      #Example code:
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

     #no loop inside

        #parse branch_length tag
        if is_element?('branch_length')
          #read in the name tag value
          @reader.read
          branch_length = @reader.value
          current_edge.distance = branch_length.to_f
          @reader.read
          has_reached_end_element?('branch_length')
        end

        #parse width tag
        #@todo write unit test for this
        #@todo put width into edge?
        parse_simple_element(current_node, 'width')


        #parse name element of the clade
        parse_simple_element(current_node, 'name')

        #parse events element
        if is_element?('events')
          current_node.events = parse_events
        end

       parse_complex_array_elements(current_node, ['confidence', 'taxonomy', 'sequence', 'distribution', 'property'])

#       if is_element?('property')
#          puts @reader.name
#          p = parse_property
#          puts p
#          puts current_node.property.class
#          if current_node == nil
#            puts "NODE IS NIL"
#          end
#          current_node.property[current_node.property.length] = p
#       end


        if is_element?('node_id')
          id = Id.new
          id.type = @reader["type"]
          @reader.read
          id.value = @reader.value
          @reader.read
          has_reached_end_element?('node_id')
          #@todo write unit test for this. There is no example of this in the example files
          current_node.id = id
        end

        if is_element?('color')
          color = BranchColor.new
          parse_simple_element(color, 'red')
          parse_simple_element(color, 'green')
          parse_simple_element(color, 'blue')
          current_node.color = color
          #@todo add unit test for this
        end

        if is_element?('date')
          date = Date.new
          parse_attributes(date, ["unit", "range"])

        #parse tags
          @reader.read #move to the next token, which is always empty, since date tag does not have text associated with it
          @reader.read #now the token is the first tag under date tag
          while not(is_end_element?('date'))
            parse_simple_element(date, 'desc')
            parse_simple_element(date, 'value')
            @reader.read
          end
          current_node.date = date
        end

        #@todo check whats up here
        if is_element?('reference')
          #@todo write unit test (there is no such tag in example file)
          reference = Reference.new
          #parse attributes
          reference.doi = @reader['doi']
          @reader.read
          #@todo test this part, maybe simplify code, since there can be max one desc tag.
          while not(is_end_element?('desc'))
            if is_element?('desc')
              reference.desc = @reader.value @reader.read
            end
            @reader.read
          end
          current_node.reference << reference
        end

    #    @reader.read
    #  end while

    end


    def parse_events()
      events = Events.new
      @reader.read #go to next element
      while not(is_end_element?('events')) do

        parse_simple_elements(events, ['type', 'duplications', 'speciations', 'losses'])

        if is_element?('confidence')
          events.confidence = parse_confidence
          #@todo add unit test for this (example file does not have this case)
        end
        @reader.read
      end
      return events
    end #parse_events


    def parse_taxonomy
      taxonomy = PhyloXMLTaxonomy.new
      parse_attributes(taxonomy, ["type", "id_source"])
      @reader.read
      while not(is_end_element?('taxonomy')) do

        parse_simple_elements(taxonomy,['code', 'scientific_name', 'rank'] )
 
        if is_element?('id')
          taxonomy.id = parse_id('id')
        end

        if is_element?('common_name')
          @reader.read
          taxonomy.common_name << @reader.value
          @reader.read
          has_reached_end_element?('common_name')
        end

        if is_element?('uri')
          taxonomy.uri = parse_uri
        end

        @reader.read  #move to next tag in the loop
      end
      return taxonomy
    end #parse_taxonomy

    def parse_sequence

      sequence = Sequence.new

      parse_attributes(sequence, ["type", "id_source", "id_ref"])

      
      #parse tags
      @reader.read
      while not(is_end_element?('sequence'))

        parse_simple_elements(sequence,['symbol', 'name', 'location', 'mol_seq', 'symbol'])

        if is_element?('accession')
          sequence.accession = Accession.new
          sequence.accession.source = @reader["source"]
          @reader.read
          sequence.accession.value = @reader.value
          @reader.read
          has_reached_end_element?('accession')
        end

        if is_element?('uri')
          sequence.uri = parse_uri
        end

        if is_element?('annotation')
          sequence.annotation << parse_annotation
        end

        if is_element?('domain_architecture')
          #@todo write unit test for this
          sequence.domain_architecture = DomainArchitecture.new
          sequence.domain_architecture.length = @reader["length"]

          @reader.read
          while not(is_end_element?('domain_architecture'))
            sequence.domain_architecture.domain << parse_domain
            @reader.read
          end
        end

        @reader.read
      end
      return sequence
    end

    def parse_uri
      #@todo add unit test for this
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

          if is_element?('confidence')
            annotation.confidence  = parse_confidence
          end          

          if is_element?('property')
            annotation.property << parse_property
          end

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

        #@todo this does not work because of the plural form
        #parse_complex_array_elements(distribution, ['point', 'polygon'])

        if is_element?('point')
          distribution.points << parse_point
        end

        if is_element?('polygon')
          #@todo add unit test
          distribution.polygons << parse_polygon
        end

        @reader.read
      end

      return distribution
    end #parse_distribution

    def parse_point
      point = Point.new

      #parse attribute
      point.geodetic_datum = @reader["geodetic_datum"]

      #parse tags
      @reader.read
      while not(is_end_element?('point')) do

        parse_simple_elements(point, ['lat', 'long'] )

        if is_element?('alt')
          @reader.read
          point.alt << @reader.value.to_f
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

        if is_element?('point')
          polygon.points << parse_point
        end

        @reader.read
      end

      if polygon.points.length <3
        puts "Warning: <polygon> should have at least 3 points"
      end
      return polygon
    end #parse_polygon

    def parse_id(tag_name)
      id = Id.new
      id.type = @reader["type"]
      @reader.read
      id.value = @reader.value
      @reader.read #@todo shouldn't there be another read?
      has_reached_end_element?(tag_name)
          #@todo write unit test for this. There is no example of this in the example files
      return id
    end

    def parse_domain
      domain = ProteinDomain.new
      parse_attributes(domain, ["from", "to", "confidence", "id"])

      @reader.read
      domain.value = @reader.value
      @reader.read
      has_reached_end_element?('domain')
      return domain
    end

  end #class phyloxml
  
end #module Bio
