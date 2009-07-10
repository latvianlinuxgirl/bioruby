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

begin #begin rescue LoadError block (test if xml is here)

require 'bio/db/phyloxml_elements'
require 'bio/db/phyloxml_parser'
require 'bio/db/phyloxml_writer'

module Bio

  module TestPhyloXMLData

  bioruby_root  = Pathname.new(File.join(File.dirname(__FILE__), ['..'] * 4)).cleanpath.to_s
  PHYLOXML_TEST_DATA = Pathname.new(File.join(bioruby_root, 'test', 'data', 'phyloxml')).cleanpath.to_s

  def self.example_xml
    File.join PHYLOXML_TEST_DATA, 'phyloxml_examples.xml'
  end

  def self.made_up_xml
    File.join PHYLOXML_TEST_DATA, 'made_up.xml'
  end

  def self.metazoa_xml
    File.join PHYLOXML_TEST_DATA, 'ncbi_taxonomy_metazoa.xml'
  end

  def self.mollusca_xml
    File.join PHYLOXML_TEST_DATA, 'ncbi_taxonomy_mollusca.xml'
  end

  def self.life_xml
    File.join PHYLOXML_TEST_DATA, 'tol_life_on_earth_1.xml'
  end

  def self.dollo_xml
    File.join PHYLOXML_TEST_DATA, 'o_tol_332_d_dollo.xml'
  end

  def self.test_xml
    File.join PHYLOXML_TEST_DATA, 'test.xml'
  end

  def self.test2_xml
    File.join PHYLOXML_TEST_DATA, 'test2.xml'
  end

  def self.mollusca_short_xml
    File.join PHYLOXML_TEST_DATA, 'ncbi_taxonomy_mollusca_short.xml'
  end

  def self.sample_xml
    File.join PHYLOXML_TEST_DATA, 'sample.xml'
  end

  end #end module TestPhyloXMLData

  class TestPhyloXMLWriter < Test::Unit::TestCase

    def test_write
      tree = Bio::PhyloXML::Tree.new
      tree.write(TestPhyloXMLData.test_xml)
    end

    def test_init
      writer = Bio::PhyloXML::Writer.new(TestPhyloXMLData.test2_xml)
      
      tree = Bio::PhyloXML::Parser.new(TestPhyloXMLData.mollusca_short_xml).next_tree
      
      writer.write(tree)

      assert_nothing_thrown do
        Bio::PhyloXML::Parser.new(TestPhyloXMLData.test2_xml)
      end
    end

    def test_simple_xml
      writer = Bio::PhyloXML::Writer.new(TestPhyloXMLData.sample_xml)
      tree = Bio::PhyloXML::Tree.new
      tree.rooted = true
      tree.name = "Test tree"
      root_node = Bio::PhyloXML::Node.new
      tree.root = root_node
      root_node.name = "A"
      #root_node.taxonomies[0] = Bio::PhyloXML::Taxonomy.new
      root_node.taxonomies << Bio::PhyloXML::Taxonomy.new
      root_node.taxonomies[0].scientific_name = "Animal animal"
      node2 = Bio::PhyloXML::Node.new
      node2.name = "B"
      tree.add_node(node2)
      tree.add_edge(root_node, node2)
      writer.write(tree)
      
      lines = File.open(TestPhyloXMLData.sample_xml).readlines()
      assert_equal("<phyloxml xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.phyloxml.org http://www.phyloxml.org/1.00/phyloxml.xsd\" xmlns=\"http://www.phyloxml.org\">",
                    lines[1].chomp)
      assert_equal("  <phylogeny rooted=\"true\">", lines[2].chomp)
      assert_equal("    <name>Test tree</name>", lines[3].chomp)
      assert_equal("    <clade>", lines[4].chomp)
      assert_equal("      <name>A</name>", lines[5].chomp)
      assert_equal("      <taxonomy>", lines[6].chomp)
      assert_equal("        <scientific_name>Animal animal</scientific_name>", lines[7].chomp)
      assert_equal("      </taxonomy>", lines[8].chomp)
      assert_equal("        <name>B</name>", lines[10].chomp)
      assert_equal("    </clade>", lines[12].chomp)
      assert_equal("  </phylogeny>", lines[13].chomp)
      assert_equal("</phyloxml>", lines[14].chomp)

    end

  end


end #end module Biof

rescue LoadError
    raise "Error: libxml-ruby library is not present. Please install libxml-ruby library. It is needed for Bio::PhyloXML module. Unit test for PhyloXML will not be performed."
end #end begin and rescue block