#
# = bio/io/phyloxml.rb - PhyloXML tree parser 
#
# Copyright::   Copyright (C) 2009
#               Diana Jaunzeikare <rozziite@gmail.com>
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

module Bio

  #---
  # PhyloXML parser
  #+++

  # PhyloXML standard phylogenetic tree parser class.
  #
  # This is alpha version. Incompatible changes may be made frequently.

  class PhyloXML

    def initialize(filename) 
      @reader = XML::Reader.file(filename)
    end
    
    def next_tree()
      tree = Bio::Tree.new()

      #current_node variable is a pointer to the current node parsed
      current_node = tree
      
      #skip until have reached clade element   
      while not((@reader.node_type==XML::Reader::TYPE_ELEMENT) and @reader.name == "clade") do 
        @reader.read
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
      end #end while not </phylogeny>   
      return tree
    end  
  
  end #class phyloxml
  
end #module Bio
