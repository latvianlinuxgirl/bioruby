#
# = bio/db/phyloxml.rb - PhyloXML Element classes
#
# Copyright::   Copyright (C) 2009
#               Diana Jaunzeikare <latvianlinuxgirl@gmail.com>
# License::     The Ruby License
#
# $Id:$
#
# == Description
#
# This file containts the classes to represent PhyloXML elements.
#
# == References
#
# * http://www.phyloxml.org
#
# * https://www.nescent.org/wg_phyloinformatics/PhyloSoC:PhyloXML_support_in_BioRuby

module Bio

  # This is general Taxonomy class.
  class Taxonomy
    #pattern = [a-zA-Z0-9_]{2,10} Swiss-prot specific in phyloXML case
    attr_accessor :code

    # String.
    attr_accessor :scientific_name
    # An array of strings
    attr_accessor :common_names

    # value comes from list: domain kingdom, subkingdom, branch, infrakingdom, superphylum, phylum, subphylum, infraphylum, microphylum, superdivision, division, subdivision, infradivision, superclass, class, subclass, infraclass, superlegion, legion, sublegion, infralegion, supercohort, cohort, subcohort, infracohort, superorder, order, suborder, superfamily, family, subfamily, supertribe, tribe, subtribe, infratribe, genus, subgenus, superspecies, species, subspecies, variety, subvariety, form, subform, cultivar, unknown, other
    attr_accessor :rank

    def inspect
      #@todo work on this / or throw it out. was used for testing.
      print "Taxonomy. scientific_name: #{@scientific_name}\n"
    end

    def initialize
      @common_names = []
    end
  end

module PhyloXML

  # Taxonomy class
  class Taxonomy < Bio::Taxonomy
    # String. Unique identifier of a taxon.
    attr_accessor :taxonomy_id
    #Used to link other elements to a taxonomy (on the xml-level).
    attr_accessor :id_source
    # Uri object
    attr_accessor :uri
  end

  # Object to hold one phylogeny element (and its subelements.) Extended version of Bio::Tree.
  class Tree < Bio::Tree
    # String
    attr_accessor :name, :description
   
    # Boolean. Can be used to indicate that the phylogeny is not allowed to be rooted differently (i.e. because it is associated with root dependent data, such as gene duplications).
    attr_accessor :rerootable

    # Boolean
    attr_accessor  :rooted

    # Array of Property object. Allows for typed and referenced properties from external resources to be attached.
    attr_accessor :properties

    # CladeRelation object. This is used to express a typed relationship between two clades. For example it could be used to describe multiple parents of a clade.
    attr_accessor :clade_relations

    # SequenceRelation object. This is used to express a typed relationship between two sequences. For example it could be used to describe an orthology.
    attr_accessor :sequence_relations

    # Array of confidence object
    attr_accessor :confidences

    # String
    attr_accessor :branch_length_unit

    # String. Indicate the type of phylogeny (i.e. 'gene tree').
    attr_accessor :type

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

    # String. Name of the node.
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


    # Converts to a Bio::Tree::Node object. If it contains several taxonomies 
    # Bio::Tree::Node#scientific name will get the scientific name of the first 
    # taxonomy.
    # 
    # If there are several confidence values, the first with bootstrap type will 
    # be returned as Bio::Tree::Node#bootstrap
    #
    # tree = phyloxmlparser.next_tree
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
      return node
    end
  end #Node

  # == Description
  # Events at the root node of a clade (e.g. one gene duplication).
  class Events
    #value comes from list: transfer, fusion, speciation_or_duplication, other, mixed, unassigned
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
      if not ['transfer','fusion','speciation_or_duplication','other','mixed', 'unassigned'].include?(str)
        puts "Warning #{str} is not one of the allowed values"
      end
    end
  end


  #@todo add documentation

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



end #module PhyloXML

end #end module Bio