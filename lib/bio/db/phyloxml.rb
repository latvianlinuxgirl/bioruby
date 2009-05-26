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
  
    attr_reader :name
  
    def name=(str)
      @name = str
    end
  
  end
  

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
      
      #skip until have reached clade element   
      while not((@reader.node_type==XML::Reader::TYPE_ELEMENT) and @reader.name == "clade") do 
        if @reader.node_type == XML::Reader::TYPE_ELEMENT and @reader.name == 'name'
          @reader.read
          tree.name = @reader.value
        end
        
        #if for some reason have reached the end of file, return nil
        #@todo take care of other stuff after phylogeny, like align:alignment
        if (@reader.node_type==XML::Reader::TYPE_END_ELEMENT and @reader.name == "phyloxml")
          return nil
        end
        
        @reader.read
        puts @reader.name if ($debug and @reader.name != nil)
      end
           
      while not((@reader.node_type==XML::Reader::TYPE_END_ELEMENT) and (@reader.name == "phylogeny")) do       
      
        #clade element
        if @reader.node_type == XML::Reader::TYPE_ELEMENT and @reader.name == 'clade'
          #read the branch length if any
          branch_length = nil
          if not @reader['branch_length']==nil 
            branch_length =  @reader['branch_length']
          end
          
          #add new node to the tree
          node= Bio::Tree::Node.new
                  
          # if tree is rooted, first node is root
          if tree.root == nil   
            tree.root = node
          else                    
            tree.add_node(node)
            tree.add_edge(current_node, node, Bio::Tree::Edge.new(branch_length))
          end
          current_node = node          
        end #end if clade           
        
        #end clade element, go one parent up
        if @reader.node_type == XML::Reader::TYPE_END_ELEMENT and @reader.name == 'clade'
          current_node = tree.parent(current_node)
        end   
        
        #processing name element of the clade
        if @reader.node_type == XML::Reader::TYPE_ELEMENT and @reader.name == 'name' 
          #read in the name tag value
          @reader.read
          current_node.name = @reader.value
          @reader.read
          if not(@reader.node_type == XML::Reader::TYPE_END_ELEMENT and @reader.name == 'name')
            puts "Warning: Should have reached </name> element here"
          end
        end
         
        @reader.read    
        if $debug and @reader.name != nil 
          print "main loop :", @reader.name, "\n"
        end
            
      end #end while not </phylogeny>   
      return tree
    end  
  
  end #class phyloxml
  
end #module Bio
