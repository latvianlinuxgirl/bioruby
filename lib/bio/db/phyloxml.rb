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
  
    attr_accessor :name, :description, :rooted
  
 
  end

  class PhyloXMLNode < Bio::Tree::Node
    #@todo not inherit from node

    
    #Events at the root node of a clade (e.g. one gene duplication).
    attr_accessor :events

    attr_accessor :id_source 
      
    attr_reader :width
    def width=(str)
      @width = str.to_f
    end

    attr_accessor :taxonomy

    #A general purpose confidence element. For example this can be used to express the bootstrap support value of a clade (in which case the 'type' attribute is 'bootstrap').
    attr_accessor :confidence

    attr_accessor :color #@todo create alias colour?

    attr_accessor :node_id #@todo create ID class with type and value

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

  class Events
    attr_accessor :type
    attr_reader :duplications
    attr_reader :speciations
    attr_reader :losses

    attr_reader :confidence

    def confidence=(type, value)
      @confidence = Confidence.new(type, value)
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
  end

  #+++
  # Taxonomy class
  #+++

  # This is general Taxonomy class.
  class Taxonomy
    #@todo sort out code
    # A general purpose identifier element. Allows to indicate the type (or source) of an identifier.
    #attr_accessor :id
    #attr_accessor :id_type


    #pattern = [a-zA-Z0-9_]{2,10} Swiss-prot secific
    attr_accessor :code

    attr_accessor :scientific_name
    #An array of strings
    attr_accessor :common_name
    # value comes from list: {'domain'|'kingdom'|'subkingdom'|'branch'|'infrakingdom'|'superphylum'|'phylum'|'subphylum'|'infraphylum'|'microphylum'|'superdivision'|'division'|'subdivision'|'infradivision'|'superclass'|'class'|'subclass'|'infraclass'|'superlegion'|'legion'|'sublegion'|'infralegion'|'supercohort'|'cohort'|'subcohort'|'infracohort'|'superorder'|'order'|'suborder'|'superfamily'|'family'|'subfamily'|'supertribe'|'tribe'|'subtribe'|'infratribe'|'genus'|'subgenus'|'superspecies'|'species'|'subspecies'|'variety'|'subvariety'|'form'|'subform'|'cultivar'|'unknown'|'other'}
    attr_accessor :rank

    def inspect
      print "Taxonomy. scientific_name: #{@scientific_name}\n"
    end
  end

  class PhyloXMLTaxonomy < Taxonomy
    attr_accessor :id
    attr_accessor :id_type
    attr_accessor :uri
  end

  class Confidence
    attr_accessor :type
    attr_accessor :value

    def initialize(type, value)
      @type = type
      @value = value
    end

  end
#

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
    attr_accessor :points #@todo Point class

    attr_accessor :polygons #@todo polygon class

    def initialize
      @points = []
      @pplygons = []
    end

  end


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
    
    #example: "P17304"
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
    attr_accessor :unit, :range, :desc, :value

    def to_s
      return "#{value} #{unit}"
    end
  end

  #DomainArchitecture class
  #
  #* length (string / int ?)
  #* domain [] (Array of ProteinDomain objects)
  #
  #ProteinDomain class
  #
  #* from (int)
  #* to (int)
  #* confidence (double) (for example, to store E-values)
  #* id (string)
  #* value (string)
  #

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
    end
    
    def file(filename)
      @reader = XML::Reader.file(filename)
    end


    
    def next_tree()
    
      puts @reader.name if ($debug and @reader.name != nil)
        
      tree = Bio::PhyloXMLTree.new()

      #current_node variable is a pointer to the current node parsed
      current_node = tree
      
      #keep track of current edge to be able to parse branch_length tag
      current_edge = nil
      
      #skip until have reached clade element, processing what pertains to the whole Tree info
      while not((@reader.node_type==XML::Reader::TYPE_ELEMENT) and @reader.name == "clade") do
        #parse attribute "rooted"
        if is_element?('phylogeny')
          @reader["rooted"] == "true" ? tree.rooted = true : tree.rooted = false
        end

        parse_simple_element(tree, 'name')  if is_element?('name')

        parse_simple_element(tree, 'description') if is_element?('description')

        if is_element?('confidence')
          tree.confidence << parse_confidence
          #@todo add unit test for this
        end
      
        
        #if for some reason have reached the end of file, return nil
        #@todo take care of other stuff after phylogeny, like align:alignment
        if is_end_element?('phyloxml')
          return nil
        end
        
        @reader.read
        puts @reader.name if ($debug and @reader.name != nil)
      end #while

      ############
      # => Now parsing clade element
      ############

      while not((@reader.node_type==XML::Reader::TYPE_END_ELEMENT) and (@reader.name == "phylogeny")) do       
      
        #clade element
        if is_element?('clade')
          #create a new node
          node= Bio::PhyloXMLNode.new
          
          #parse attributes of the clade element
          branch_length = @reader['branch_length']
          node.id_source = @reader['id_source']

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
        
        #parse name element of the clade
        parse_simple_element(current_node, 'name')  if is_element?('name')
        
        #parse branch_length tag
        if is_element?('branch_length')
          #read in the name tag value
          @reader.read
          branch_length = @reader.value
          current_edge.distance = branch_length.to_f
        end 

        #parse width tag
        #@todo write unit test for this
        #@todo put width into edge?
        parse_simple_element(current_node, 'width')  if is_element?('width')

        #parse confidence tag
        if is_element?('confidence')
          current_node.confidence << parse_confidence
        end        

        #parse events element
        if is_element?('events')
          current_node.events = parse_events
        end

        if is_element?('taxonomy')          
          current_node.taxonomy << parse_taxonomy
        end

        if is_element?('sequence')
          current_node.sequence << parse_sequence
        end

        if is_element?('distribution')
          current_node.distribution << parse_distribution
        end

        if is_element?('node_id')
          id = Id.new
          id.type = @reader["type"]
          @reader.read
          id.value = @reader.value
          has_reached_end_tag?('node_id')
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

        
        #end clade element, go one parent up
        if is_end_element?('clade') 
          current_node = tree.parent(current_node)
        end          
        
        # go to next element        
        @reader.read    
        if $debug and @reader.name != nil 
          print "main loop :", @reader.name, "\n"
        end
            
      end #end while not </phylogeny>   
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

    def has_reached_end_tag?(str)
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
        has_reached_end_tag?(name)
      end
    end

    def parse_events()
      events = Events.new
      @reader.read #go to next element
      while not(is_end_element?('events')) do
        #@todo check if value for type elemnt is is from allowed list
        parse_simple_element(events, 'type')  if is_element?('type')

        ['duplications', 'speciations', 'losses'].each { |elmt|
          parse_simple_element(events, elmt)  if is_element?(elmt)
        }
        if is_element?('confidence')
          events.confidence = parse_confidence
          #@todo add unit test for this
        end
        @reader.read
      end
      return events
    end #parse_events


    def parse_taxonomy
      taxonomy = PhyloXMLTaxonomy.new
      #@todo parse taxonomy attributes
      @reader.read
      while not(is_end_element?('taxonomy')) do

        parse_simple_element(taxonomy, 'scientific_name') if is_element?('scientific_name')
        parse_simple_element(taxonomy, 'code') if is_element?('code')

        @reader.read      
      end
      return taxonomy
    end #parse_taxonomy

    def parse_sequence

      sequence = Sequence.new

      #parse attributes
      sequence.type = @reader['type']
      sequence.id_source = @reader['id_source']
      sequence.id_ref = @reader['id_ref']

      #parse tags
      @reader.read
      while not(is_end_element?('sequence'))

        ['symbol', 'name', 'location', 'mol_seq'].each {|elem|
          parse_simple_element(sequence, elem) if is_element?(elem)
        }

        parse_simple_element(sequence, 'symbol') if is_element?('symbol')

        if is_element?('accession')
          sequence.accession = Accession.new
          sequence.accession.source = @reader["source"]
          @reader.read
          sequence.accession.value = @reader.value
          @reader.read
          has_reached_end_tag?('accession')
        end

        if is_element?('uri')
          sequence.uri = parse_uri
        end

        if is_element?('annotation')
          sequence.annotation << parse_annotation
        end


        @reader.read
      end
      return sequence
    end

    def parse_uri
      #@todo add unit test for this
      uri = Uri.new
      uri.desc = @reader["desc"]
      uri.type = @reader["type"]
      parse_simple_element(uri, 'uri')
      return uri
    end

    def parse_annotation
      annotation = Annotation.new

      #parse attributes
      annotation.ref = @reader["ref"]
      annotation.source = @reader["source"]
      annotation.evidence = @reader["evidence"]
      annotation.type = @reader["type"]

      if @reader.empty_element?
        return annotation
      else
        while not(is_end_element?('annotation'))
          parse_simple_element(annotation, 'desc') if is_element?('desc')

          if is_element?('confidence')
            annotation.confidence  = parse_confidence
          end          

          #@todo parse_property
          if is_element?('property')
            annotation.property << parse_property
          end

          if is_element?('uri')
            annotation.uri = parse_uri
            #@todo add unit test to this
          end

          @reader.read
        end
        return annotation
      end      
    end

    def parse_property
      #@todo
      return nil
    end

    def parse_confidence
      #@todo does it matter if it is float or integer?
      type = @reader["type"]
      @reader.read
      value = @reader.value.to_f
      @reader.read
      has_reached_end_tag?('confidence')
      return Confidence.new(type, value)
    end #parse_confidence

    def parse_distribution
      distribution = Distribution.new

      @reader.read

      while not(is_end_element?('distribution')) do

        parse_simple_element(distribution, 'desc') if is_element?('desc')
 
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

        ['lat', 'long'].each { |elemnt|
          parse_simple_element(point, elemnt) if is_element?(elemnt)
        }

        if is_element?('alt')
          @reader.read
          point.alt << @reader.value.to_f
          @reader.read
          has_reached_end_tag?('alt')
        end
        #advance reader
        @reader.read
      end
      return point
    end #parse_point

    def parse_polygon
      polygon = Polygon.new

      @reader.read
      #@todo consider renaming is_end_element has_reached_end_tag? so that it is either element or tag
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



  end #class phyloxml
  
end #module Bio
