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
  
    def setup
      @phyloxml = Bio::PhyloXML.new(TestPhyloXMLData.example_xml)
    end
    
    def test_init
      assert_equal(@phyloxml.class, Bio::PhyloXML)
    end 
      
    def test_next_tree
      tree = @phyloxml.next_tree
      tree_arr = []
      while tree != nil do
        tree_arr[tree_arr.length] = tree.name
        tree = @phyloxml.next_tree
      end      
      assert_equal(tree_arr.length, 13)
    end
     
  end #class TestPhyloXML

  class TestPhyloXML2 < Test::Unit::TestCase
  
    #setup is called before and every time any function es executed.  
    def setup
      @phyloxml = Bio::PhyloXML.new(TestPhyloXMLData.example_xml)
      @tree = @phyloxml.next_tree
    end
    
    def test_tree_name
      assert_equal(@tree.name, "example from Prof. Joe Felsenstein's book \"Inferring Phylogenies\"")
    end
    
    def test_tree_description
      assert_equal(@tree.description, "phyloXML allows to use either a \"branch_length\" attribute or element to indicate branch lengths.")
    end
    
    def test_branch_length_attribute
      assert_equal(@tree.total_distance, 0.792)
    end

    def test_rooted_atr
       assert_equal(@tree.rooted, true)
    end
    
   
    def test_branch_length_tag
      @tree = @phyloxml.next_tree
      assert_equal(@tree.total_distance, 0.792)
    end
    
    def test_bootstrap
      #iterate throuch first 2 trees to get to the third
      @tree = @phyloxml.next_tree
      @tree = @phyloxml.next_tree
      node = @tree.get_node_by_name("AB")
      assert_equal(node.confidence[0].type, 'bootstrap')
      assert_equal(node.confidence[0].value, 89)
    end

    def test_duplications
      4.times do
        @tree = @phyloxml.next_tree
      end
      node = @tree.root
      assert_equal(node.events.speciations, 1)
    end

    #@todo should this be in a separate file?
    def test_taxonomy_scientific_name
      3.times do
        @tree = @phyloxml.next_tree
      end
      t = @tree.get_node_by_name('A').taxonomy[0]
      assert_equal(t.scientific_name, 'E. coli')
      t = @tree.get_node_by_name('C').taxonomy[0]
      assert_equal(t.scientific_name, 'C. elegans')
    end

    def test_taxonomy_id
      5.times do
        @tree = @phyloxml.next_tree
      end
      leaves = @tree.leaves
      codes = []
      ids = []
      #id_types = []
      leaves.each { |node|
        codes[codes.length] = node.taxonomy[0].code
        ids[ids.length] = node.taxonomy[0].id
        #id_types[id_types.length] = node.taxonomy.id_type
      }
      assert_equal(codes.sort, ["CLOAB",  "DICDI", "OCTVU"])
     #@todo assert ids, id_types. or create new class for id.
    end

    def test_taxonomy_rank

    end

    
  end #class TestPhyloXML2
  
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
