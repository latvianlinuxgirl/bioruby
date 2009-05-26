#
# = test/bio/db/phyloxml.rb - Unit test for Bio::PhyloXML
#
# Copyright::   Copyright (C) 2009
#               Diana Jaunzeikare <latvianlinuxgirl@gmail.com>
# License::     The Ruby License
#

require 'test/unit'

#this code is required for being able to require 'bio/db/phyloxml'
require 'pathname'
libpath = Pathname.new(File.join(File.dirname(__FILE__), ['..'] * 4, 'lib')).cleanpath.to_s
$:.unshift(libpath) unless $:.include?(libpath)

require 'bio'
require 'bio/tree'
require 'bio/db/phyloxml'

module TestPhyloXMLData

  bioruby_root  = Pathname.new(File.join(File.dirname(__FILE__), ['..'] * 4)).cleanpath.to_s
  TEST_DATA = Pathname.new(File.join(bioruby_root, 'test', 'data', 'phyloxml')).cleanpath.to_s

  def self.example_xml
    File.join TEST_DATA, 'phyloxml_examples.xml'
  end

end #end module TestPhyloXMLData


module Bio

  class TestPhyloXML < Test::Unit::TestCase
    
    def test_init
      phyloxml = Bio::PhyloXML.new(TestPhyloXMLData.example_xml)
      assert_equal(phyloxml.class, Bio::PhyloXML)
    end 
      
    def test_get_first_tree
    
      phyloxml = Bio::PhyloXML.new(TestPhyloXMLData.example_xml)
      tree = phyloxml.next_tree()      
      assert_equal(tree.number_of_nodes, 5)       
    end
     
  end #class TestPhyloXML

  
  class TestPhyloXML3 < Test::Unit::TestCase
  
  TEST_STRING = 
  """<phylogeny rooted=\"true\">
      <name>same example, with support of type \"bootstrap\"</name>
      <clade>
         <clade branch_length=\"0.06\">
            <name>AB</name>
            <confidence type=\"bootstrap\">89</confidence>
            <clade branch_length=\"0.102\">
               <name>A</name>
            </clade>
            <clade branch_length=\"0.23\">
               <name>B</name>
            </clade>
         </clade>
         <clade branch_length=\"0.4\">
            <name>C</name>
         </clade>
      </clade>
   </phylogeny>"""
   
    def setup
      phyloxml = Bio::PhyloXML.new(TEST_STRING)
      @tree = phyloxml.next_tree()  

    end
  
    def test_children
      node =  @tree.get_node_by_name("AB")
      # nodes  = @tree.children(node).sort { |a,b| a.name <=> b.name }
      node_names = []
      @tree.children(node).each { |node|
        node_names[node_names.length] = node.name
      }
      node_names.sort!
      assert_equal(node_names, ["A", "B"])
    end
  
  end # class


end #end module Bio
