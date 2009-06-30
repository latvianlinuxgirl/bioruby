#
# = bio/db/phyloxml.rb - PhyloXML parser
#
# Copyright::   Copyright (C) 2009
#               Diana Jaunzeikare <latvianlinuxgirl@gmail.com>
# License::     The Ruby License
#
# $Id:$
#
# == Description
#
# This file containts parser for PhyloXML and all the classes to represent PhyloXML elements.
#
# == Requirements
# 
# Libxml2 XML parser is required. Install libxml-ruby bindings from http://libxml.rubyforge.org or
#
#   gem install -r libxml-ruby
#
# == References
#
# * http://www.phyloxml.org
#
# * https://www.nescent.org/wg_phyloinformatics/PhyloSoC:PhyloXML_support_in_BioRuby

require 'bio/tree'

require 'xml'

module Bio

   #+++
  # Taxonomy class
  #+++

  # This is general Taxonomy class.
  class Taxonomy
    #pattern = [a-zA-Z0-9_]{2,10} Swiss-prot specific in phyloXML case
    attr_accessor :code

    attr_accessor :scientific_name
    #An array of strings
    attr_accessor :common_names
    # value comes from list: {'domain'|'kingdom'|'subkingdom'|'branch'|'infrakingdom'|'superphylum'|'phylum'|'subphylum'|'infraphylum'|'microphylum'|'superdivision'|'division'|'subdivision'|'infradivision'|'superclass'|'class'|'subclass'|'infraclass'|'superlegion'|'legion'|'sublegion'|'infralegion'|'supercohort'|'cohort'|'subcohort'|'infracohort'|'superorder'|'order'|'suborder'|'superfamily'|'family'|'subfamily'|'supertribe'|'tribe'|'subtribe'|'infratribe'|'genus'|'subgenus'|'superspecies'|'species'|'subspecies'|'variety'|'subvariety'|'form'|'subform'|'cultivar'|'unknown'|'other'}
    attr_accessor :rank

    def inspect
      #@todo work on this / or throw it out. was used for testing.
      print "Taxonomy. scientific_name: #{@scientific_name}\n"
    end

    def initialize
      @common_names = []
    end
  end

  # == Description
  #
  # Bio::PhyloXML is for parsing phyloXML format files.
  # This is alpha version. Incompatible changes may be made frequently.
  #
  # == Requirements
  #
  # Libxml2 XML parser is required. Install libxml-ruby bindings from http://libxml.rubyforge.org or
  #
  #   gem install -r libxml-ruby
  #
  # == Usage
  #
  #   require 'bio'
  #
  #   # Create new phyloxml reader
  #   phyloxml = Bio::PhyloXML.new("./phyloxml_examples.xml")
  #
  #   # Print the names of all trees in the file
  #   while tree != nil do
  #     tree = phyloxml.next_tree
  #     puts tree.name
  #   end
  #
  # == References
  #
  # http://www.phyloxml.org/documentation/version_100/phyloxml.xsd.html
  #
  class PhyloXML

    class Tree < Bio::Tree
      # String
      attr_accessor :name, :description
      # Boolean
      attr_accessor :rerootable, :rooted
      
      # Array of Property object
      attr_accessor :properties

      # CladeRelation object
      attr_accessor :clade_relations
      
      # SequenceRelation object
      attr_accessor :sequence_relations
      
      # Array of confidence object
      attr_accessor :confidences

      # String
      attr_accessor :branch_length_unit, :type

     def initialize
       super
       @sequence_relations = []
       @clade_relations = []
       @confidences = []
       @properties = []
     end

    end

    # == Description
    # Class to hold clade element of phyloXML.
    class Node

      # Events at the root node of a clade (e.g. one gene duplication).
      attr_accessor :events

      # String. Used to link other elements to a clade (node) (on the xml-level).
      attr_accessor :id_source

      # String
      attr_accessor :name

      # Float. Branch width for this node (including parent branch). Applies for the whole clade unless overwritten in sub-clades.
      attr_reader :width
      
      def width=(str)
        @width = str.to_f
        #@todo maybe this attr should be part of Bio::Tree::Edge
      end

      # Array of Taxonomy objects. Describes taxonomic information for a clade.
      attr_accessor :taxonomies

      # Array of Confidence objects. Indicates the support for a clade/parent branch.
      attr_accessor :confidences

      # BranchColor object. Apply for the whole clade unless overwritten in sub-clade.
      attr_accessor :color

      # Id object
      attr_accessor :node_id

      # Array of Sequence objects. Represents a molecular sequence (Protein, DNA, RNA) associated with a node.
      attr_accessor :sequences

      # BinaryCharacters object. The names and/or counts of binary characters present, gained, and lost at the root of a clade.
      attr_accessor :binary_characters

      # Array of Distribution objects. The geographic distribution of the items of a clade (species, sequences), intended for phylogeographic applications.
      attr_accessor :distributions

      # Date object. A date associated with a clade/node.
      attr_accessor :date

      #Array of Reference objects. A literature reference for a clade.
      attr_accessor :references

      #An array of Property objects, for example depth for sea animals.
      attr_accessor :properties

      def initialize
        @confidences = []
        @sequences = []
        @taxonomies = []
        @distributions = []
        @references = []
        @properties = []
      end


      # tree = phyloxml.next_tree
      # 
      # node = tree.get_node_by_name("A").to_biotreenode
      # 
      # ---
      # *Returns*:: Bio::Tree::Node
      def to_biotreenode
        node = Bio::Tree::Node.new
        node.name = @name
        node.scientific_name = @taxonomies[0].scientific_name if not @taxonomies.empty?
        #@todo what if there are more?
        node.taxonomy_id = @taxonomies[0].taxononmy_id if @taxonomies[0] != nil

        if not @confidences.empty?
          @confidences.each do |confidence|
            if confidence.type == "bootstrap"
              node.bootstrap = confidence.value
              break
            end
          end
        end
        #@todo write unit test for case with two bootstrap values, for probability and bootstrap, and just probability.
        return node
      end
    end #Node


    # Element 'id' is used for a unique identifier of a taxon (for example '6500'
    # with 'ncbi_taxonomy' as 'type' for the California sea hare). Attribute
    # 'id_source' is used to link other elements to a taxonomy (on the xml-level).
    class Taxonomy < Bio::Taxonomy
      # String
      attr_accessor :taxonomy_id, :id_source
      # Uri object
      attr_accessor :uri
    end

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

    # == Description
    #
    # The geographic distribution of the items of a clade (species, sequences),
    # intended for phylogeographic applications. The location can be described
    # either by free text in the 'desc' element and/or by the coordinates of
    # one or more 'Points' (similar to the 'Point' element in Google's KML
    # format) or by 'Polygons'.
    class Distribution
      # String
      attr_accessor :desc
      # Array of Point objects
      attr_accessor :points
      # Array of Polygon objects
      attr_accessor :polygons

      def initialize
        @points = []
        @polygons = []
      end
    end #Distribution class

    # == Description
    #
    # The coordinates of a point with an optional altitude (used by element
    # 'Distribution'). Required attribute 'geodetic_datum' is used to indicate
    # the geodetic datum (also called 'map datum'), for example
    # Google's KML uses 'WGS84'.
    class Point
      attr_accessor :lat, :long, :alt, :geodetic_datum

      def lat=(str)
        @lat = str.to_f
      end

      def long=(str)
        @long = str.to_f
      end

      def alt=(str)
        @alt = str.to_f
        #@todo add unit test for this
      end

    end

    # == Description
    # 
    # A polygon defined by a list of 'Points'
    class Polygon
      # Array of Point objects
      attr_accessor :points

      def initialize
        @points = []
      end
    end

    # == Description
    # Element Sequence is used to represent a molecular sequence (Protein, DNA,
    # RNA) associated with a node.   
    class Sequence
      # Type of sequence (rna, dna, aa)
      attr_accessor :type

      # Full name (e.g. muscle Actin )
      attr_accessor :name

      # String
      attr_accessor :id_source

      # String. One intended use for 'id_ref' is to link a sequence to a taxonomy
      # (via the taxonomy's 'id_source') in the case of multiple sequences and taxonomies per node.
      attr_accessor :id_ref
      # 'symbol' is a short (maximal ten characters) symbol of the sequence (e.g. 'ACTM')
      attr_accessor :symbol
      # Accession object
      attr_accessor :accession
      # Location of a sequence on a genome/chromosome
      attr_accessor :location
      # String. The actual sequence is stored here.
      attr_accessor :mol_seq
      # Uri object
      attr_accessor :uri #@todo alias method url ?
      # Array of Annotation objects
      attr_accessor :annotations
      # DomainArchitecture object
      attr_accessor :domain_architecture

      def initialize
        @annotations = []
      end

      # converts Bio::PhyloXML:Sequence to Bio::Sequence object.
      # ---
      # *Returns*:: Bio::Tree::Sequence
      def to_biosequence
        #type is not a required attribute in phyloxml (nor any other Sequence
        #element) it might not hold any value, so we will not check what type it is.
        seq = Bio::Sequence.auto(@mol_seq)

        seq.id_namespace = @accession.source
        seq.entry_id = @accession.value
       # seq.primary_accession = @accession.value could be this
        seq.definition = @name
        #seq.comments = @name //this one?
        if @uri != nil
          h = {'url' => @uri.uri,
            'title' => @uri.desc }
          ref = Bio::Reference.new(h)
          seq.references << ref
        end
        seq.molecule_type = 'RNA' if @type == 'rna'
        seq.molecule_type = 'DNA' if @type == 'dna'


        #seq.classification = get from taxonomy
        #seq.species => get from taxonomy
        #seq.division => ..

        #@todo deal with the properties. There might be properties which look
        #like bio sequence attributes or features
        return seq
      end

    end

    # == Description
    # Element Accession is used to capture the local part in a sequence
    # identifier.
    class Accession
      #Example: "UniProtKB"
      attr_accessor :source

      #Example: "P17304"
      attr_accessor :value 
    end


    class Uri
      # String
      attr_accessor :desc
      # String
      attr_accessor :type
      attr_accessor :uri #@todo call it url?
    end

    # == Description
    #
    # The annotation of a molecular sequence.
    class Annotation
      # String
      attr_accessor :ref
      # String
      attr_accessor :source
      # String
      attr_accessor :evidence
      # String
      attr_accessor :type
      # String
      attr_accessor :desc
      # Confidence object
      attr_accessor :confidence
      # Array of Property objects
      attr_accessor :properties
      # Uri object
      attr_accessor :uri

      
      def initialize
        #@todo add unit test for this, since didn't break anything when changed from property to properties
        @properties = []
      end
    end

    class Id
      attr_accessor :type, :value
    end

    # == Description
    # This indicates the color of a node when rendered (the color applies
    # to the whole node and its children unless overwritten by the
    # color(s) of sub clades).
    class BranchColor
      #Integer
      attr_reader :red, :green, :blue

      def red=(str)
        @red = str.to_i
      end

      def green=(str)
        @green = str.to_i
      end

      def blue=(str)
        @blue = str.to_i
      end

      #@todo maybe should be part of Bio::Tree::Edge
    end

    # == Description
    # A date associated with a clade/node. Its value can be numerical by 
    # using the 'value' element and/or free text with the 'desc' element' 
    # (e.g. 'Silurian'). If a numerical value is used, it is recommended to 
    # employ the 'unit' attribute to indicate the type of the numerical 
    # value (e.g. 'mya' for 'million years ago').
    class Date
      attr_accessor :unit,  :desc

      attr_reader :range, :value

      def range=(str)
        @range = str.to_i
      end

      def value= (str)
        @value = str.to_i
      end

      # Returns value + unit, for exampe "7 mya"
      def to_s
        return "#{value} #{unit}"
      end
    end

    # == Description
    # This is used describe the domain architecture of a protein. Attribute
    # 'length' is the total length of the protein
    class DomainArchitecture
      attr_accessor :length
      attr_reader :domains

      def length=(str)
        @length = str.to_i
      end

      def initialize
        @domains = []
      end
    end

    # == Description
    # To represent an individual domain in a domain architecture. The
    # name/unique identifier is described via the 'id' attribute.
    class ProteinDomain
      #String, for example to store E-values
      attr_accessor :confidence

      # String
      attr_accessor :id, :value

      # Integer
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
      # String
      attr_accessor :ref, :unit, :id_ref, :value

      # String
      attr_reader :datatype, :applies_to
     
      def datatype=(str)
         #@todo add unit test or maybe remove, if assume that xml is valid.
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
        @datatype = str
      end

      def applies_to=(str)
        unless ['phylogeny','clade','node','annotation','parent_branch','other'].include?(str)
          puts "Warning: #{str} is not in the list of allowed values."
        end
        @applies_to = str
      end
    end

    # == Description
    # A literature reference for a clade. It is recommended to use the 'doi'
    # attribute instead of the free text 'desc' element whenever possible.
    class Reference
      # String
      attr_accessor :doi, :desc

      #@todo should use Bio::Reference
    end

    # == Description
    #
    # This is used to express a typed relationship between two clades.
    # For example it could be used to describe multiple parents of a clade.
    class CladeRelation
      # Float
      attr_accessor :distance
      # String
      attr_accessor :id_ref_0, :id_ref_1, :type
      # Confidence object
      attr_accessor :confidence

      def distance=(str)
        @distance = str.to_f
      end
      
    end

    # == Description
    # The names and/or counts of binary characters present, gained, and
    # lost at the root of a clade.
    class BinaryCharacters
      attr_accessor :type, :gained, :lost, :present, :absent
      attr_reader :gained_count, :lost_count, :present_count, :absent_count
       
      def gained_count=(str)
        @gained_count = str.to_i
      end

      def lost_count=(str)
        @lost_count = str.to_i
      end

      def present_count=(str)
        @present_count = str.to_i
      end

      def absent_count=(str)
        @absent_count = str.to_i
      end

      def initialize
        @gained = []
        @lost = []
        @present = []
        @absent = []
      end

    end

    # == Description
    # This is used to express a typed relationship between two sequences.
    # For example it could be used to describe an orthology (in which case
    # attribute 'type' is 'orthology').
    class SequenceRelation
      # String
      attr_accessor :id_ref_0, :id_ref_1, :type
      # Float
      attr_reader :distance

      def distance=(str)
        @distance = str.to_i
      end

    end

    # == Description
    # Events at the root node of a clade (e.g. one gene duplication).
    class Events
      #value comes from list: {'transfer'|'fusion'|'speciation_or_duplication'|'other'|'mixed'|'unassigned'}
      attr_accessor :type
      # Integer
      attr_reader :duplications, :speciations, :losses
      # Confidence object
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
        #@todo probably don't need this if the xml files are valid against the xsd schema
        if not ['transfer','fusion','speciation_or_duplication','other','mixed', 'unassigned'].include?(str)
          puts "Warning #{str} is not one of the allowed values"
        end
      end
    end


    ###########################################################################


    # Initializes LibXML::Reader and reads the file until reaches first
    # phylogeny element.
    #
    # Create a new Bio::PhyloXML object.
    #
    #   p = Bio::PhyloXML.new("./phyloxml_examples.xml")
    #
    # ---
    # *Arguments*:
    # * (required) _str_: String 
    # *Returns*:: Bio::PhyloXML object
    def initialize(str) 
      #@todo decide if need to be able initialize using string, since usually xml lives in files

      #check if parameter is a valid file name
      if File.exists?(str) 
        @reader = XML::Reader.file(str)
      else 
        #assume it is string input
        @reader = XML::Reader.string(str)
      end

      #@todo deal with stuff before has reached that

      #loops through until reaches phylogeny stuff
      while not is_element?('phylogeny')
        @reader.read
      end
    end
    
    def file(filename)
      @reader = XML::Reader.file(filename)
    end

    # Parse and return the next phylogeny tree.
    # 
    # p = Bio::PhyloXML.new("./phyloxml_examples.xml")
    # 
    # tree = p.next_tree
    #
    # ---
    # *Returns*:: Bio::PhyloXML::Tree
    def next_tree()

      #@todo what about a method for skipping a tree. (might save on time by not creating all those objects)

      if not is_element?('phylogeny')
        #print "Warning: This should have been phylogeny element, but it is: ", @reader.name, " ", @reader.value, "\n"

        #@todo deal with rest of the stuff, maybe read in as text and add it to PhyloXML
        #for now ignore the rest of the stuff
        #and loop until the next phylogeny element if there is one, in case 
        #there are more phylogeny elements after other stuff, so that next read 
        #is successful
        while is_element?('phylogeny') or is_end_element?('phyloxml')
          @reader.read
        end
        return nil
      end

      tree = Bio::PhyloXML::Tree.new()

      #current_node variable is a pointer to the current node parsed
      #@todo might need to change this, since node should point to a node, not tree
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

        # parse phylogeny elements, except clade
        if not parsing_clade

          if is_element?('phylogeny')
            @reader["rooted"] == "true" ? tree.rooted = true : tree.rooted = false
          end

          #@todo add unit tests for this
          parse_attributes(tree, ['rerootable', 'branch_length_unit', 'type'])

          parse_simple_elements(tree, ['name', 'description'])

          if is_element?('confidence')
            tree.confidences << parse_confidence
          end

        end

        #parse clade element
        if is_element?('clade')
          parsing_clade = true 
          
          node= Bio::PhyloXML::Node.new
          
          #parse attributes of the clade element
          #@todo this is not consistent with the way i parse attributes
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

           #if we have reached the closing tag of the top-most clade, then our
          # curent node should point to the root, If thats the case, we are done
          # parsing the clade element
          if current_node == tree.root
            parsing_clade = false
          else
            current_node = tree.parent(current_node)
          end
        end          

        parse_clade_elements(current_node, current_edge) if parsing_clade

        #parsing phylogeny elements
        if not parsing_clade
          #@todo add unit test for this
          if is_element?('property')
            tree.properties << parse_property
          end          

          if is_element?('clade_relation')
            clade_relation = CladeRelation.new
            parse_attributes(clade_relation, ["id_ref_0", "id_ref_1", "distance", "type"])

            #@todo add unit test for this
            if not @reader.empty_element?
              @reader.read
              if is_element?('confidence')
                clade_relation.confidence = parse_confidence
              end
            end
            tree.clade_relations << clade_relation
          end

          if is_element?('sequence_relation')
            
            sequence_relation = SequenceRelation.new
            parse_attributes(sequence_relation, ["id_ref_0", "id_ref_1", "distance", "type"])


            if not @reader.empty_element?
              @reader.read
              if is_element?('confidence')
                sequence_relation.confidence = parse_confidence
              end
            end
            tree.sequence_relations << sequence_relation           
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
      # @todo make this work for plural forms
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

      if is_element?('branch_length')
        @reader.read
        branch_length = @reader.value
        current_edge.distance = branch_length.to_f
        @reader.read
        has_reached_end_element?('branch_length')
      end

      #@todo write unit test for width tag
      #@todo put width into edge?
      parse_simple_elements(current_node, ['width', 'name'])

      current_node.events = parse_events if is_element?('events')

      #parse_complex_array_elements(current_node, ['confidence', 'sequence', 'property'])
      #@todo will have to deal with plural forms

      current_node.confidences << parse_confidence if is_element?('confidence')
      current_node.sequences << parse_sequence if is_element?('sequence')
      current_node.properties << parse_property if is_element?('property')
      current_node.taxonomies << parse_taxonomy if is_element?('taxonomy')
      current_node.distributions << parse_distribution if is_element?('distribution')

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

        #move to the next token, which is always empty, since date tag does not
        # have text associated with it
        @reader.read 
        @reader.read #now the token is the first tag under date tag
        while not(is_end_element?('date'))
          parse_simple_element(date, 'desc')
          parse_simple_element(date, 'value')
          @reader.read
        end
        current_node.date = date
      end

      if is_element?('reference')
        #@todo write unit test (there is no such tag in example file)
        
        reference = Reference.new()
        reference.doi = @reader['doi']      
        if not @reader.empty_element?
          while not is_end_element?('reference')
            parse_simple_element(reference, 'desc')
            @reader.read
          end
        end
        current_node.references << reference
      end

      current_node.binary_characters  = parse_binary_characters if is_element?('binary_characters')


      
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
        parse_simple_elements(taxonomy,['code', 'scientific_name', 'rank'] )

        taxonomy.taxonomy_id = parse_id('id') if is_element?('id')

        if is_element?('common_name')
          @reader.read
          taxonomy.common_names << @reader.value
          @reader.read
          has_reached_end_element?('common_name')
        end

        taxonomy.uri = parse_uri if is_element?('uri')

        @reader.read  #move to next tag in the loop
      end
      return taxonomy
    end #parse_taxonomy

    def parse_sequence
      sequence = Sequence.new
      parse_attributes(sequence, ["type", "id_source", "id_ref"])
      
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

        sequence.uri = parse_uri if is_element?('uri')

        sequence.annotations << parse_annotation if is_element?('annotation')

        if is_element?('domain_architecture')
          #@todo write unit test for domain_architecture
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
    end #parse_sequence

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

      #@should check for it at all?
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
    end #parse_id

    def parse_domain
      domain = ProteinDomain.new
      parse_attributes(domain, ["from", "to", "confidence", "id"])

      @reader.read
      domain.value = @reader.value
      @reader.read
      has_reached_end_element?('domain')
      return domain
    end

    def parse_binary_characters
      #@todo write a test case and example data for this.
      b = PhyloXML::BinaryCharacters.new

      parse_attributes(b, ['type', 'gained_count', 'absent_count', 'lost_count', 'present_count'])

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

  end #class phyloxml
  
end #module Bio
