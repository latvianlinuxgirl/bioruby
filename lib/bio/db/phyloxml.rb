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

  #---
  # PhyloXML parser
  #+++

  # PhyloXML standard phylogenetic tree parser class.
  #
  # This is alpha version. Incompatible changes may be made frequently.
  class PhyloXMLTree < Bio::Tree
  
    attr_accessor :name, :description, :rooted
  
 
  end

  class PhyloXMLNode < Bio::Tree::Node
    
    attr_accessor :events

  end

  class Events
    attr_accessor :type, :duplications, :speciations, :losses

    attr_reader :confidence

    def confidence=(type, value)
      @confidence = Confidence.new(type, value)
    end

  end

  class PhyloXML

    class Confidence
      attr_accessor :type, :value

      def initialize(type, value)
        @type = type
        @value = value
      end

    end


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

        if is_element?('name')
          @reader.read
          tree.name = @reader.value
          @reader.read
          has_reached_end_tag?('name')
        end
        
        #parse_tag(description, tree) parse the tag description and add to tree object
        
        #@todo looks like code repetition, put in a function / macro
        if is_element?('description')
          @reader.read
          tree.description = @reader.value
          @reader.read
          has_reached_end_tag?('description')
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
          
          #parse attributes of the clade
          #read the branch length if any
          branch_length = nil
          if not @reader['branch_length']==nil 
            branch_length =  @reader['branch_length']
          end
          
          #add new node to the tree
          node= Bio::PhyloXMLNode.new
                  
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
        if is_element?('name')
          #read in the name tag value
          @reader.read
          current_node.name = @reader.value
          @reader.read
          has_reached_end_tag?('name')
        end
        
        
        #parse branch_length tag
        if is_element?('branch_length')
          #read in the name tag value
          @reader.read
          branch_length = @reader.value
          current_edge.distance = branch_length.to_f
        end 
        
        #parse confidence tag
        if is_element?('confidence')
          if @reader["type"]=="bootstrap"
            #read in the tag value
            @reader.read
            node.bootstrap = @reader.value.to_f
            @reader.read
            has_reached_end_tag?('confidence')
          end          
        end        


        #parse events element
        if is_element?('events')
          current_node.events = parse_events
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

    def parse_events()
      events = Events.new

      @reader.read #go to next element
      #read while have reached end of events
      while not(is_end_element?('events')) do
        if is_element?('type')
          #@todo check if value is from allowed list
          @reader.read
          events.type = @reader.value
          @reader.read
          has_reached_end_tag?('type')
        end
        if is_element?('duplications')
          @reader.read
          events.duplications = @reader.value.to_i
          @reader.read
          has_reached_end_tag?('duplications')
        end
        if is_element?('speciations')
          @reader.read
          events.speciations = @reader.value.to_i
          @reader.read
          has_reached_end_tag?('speciations')
        end
        if is_element?('losses')
          @reader.read
          events.losses = @reader.value.to_i
          @reader.read
          has_reached_end_tag?('losses')
        end
        #@todo parse confidence tag

        @reader.read
      end
      return events
    end

  end #class phyloxml
  
end #module Bio
