#
# = test/bio/db/phyloxml.rb - Unit test for Bio::PhyloXML
#
# Copyright::   Copyright (C) 2009
#               Diana Jaunzeikare <rozziite@gmail.com>
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

end #end module Bio
