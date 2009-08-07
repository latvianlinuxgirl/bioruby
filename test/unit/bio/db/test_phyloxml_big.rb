#
# = test/bio/db/phyloxml.rb - Unit test for Bio::PhyloXML. Testing very big files.
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

puts libpath

require 'bio'
require 'bio/tree'
require 'bio/db/phyloxml_parser'


module TestPhyloXMLBigData

  bioruby_root  = Pathname.new(File.join(File.dirname(__FILE__), ['..'] * 4)).cleanpath.to_s
  PHYLOXML_TEST_DATA = Pathname.new(File.join(bioruby_root, 'test', 'data', 'phyloxml')).cleanpath.to_s

  def self.metazoa_xml
    puts "Metazoa 30MB"
    File.join PHYLOXML_TEST_DATA, 'ncbi_taxonomy_metazoa.xml'
  end

  def self.mollusca_xml
    puts "Mollusca 1.5MB"
    File.join PHYLOXML_TEST_DATA, 'ncbi_taxonomy_mollusca.xml'
  end

  def self.unzip_file(file, target_dir)
    `unzip #{file}.zip -d #{target_dir}`
  end

  def self.life_xml
    #Right now this file is not compactible with xsd 1.10
    filename = 'tol_life_on_earth_1.xml'
    file = File.join PHYLOXML_TEST_DATA, filename
    if File.exists?(file)
      return file
    else

      if File.exists?("#{file}.zip")
        self.unzip_file(file, PHYLOXML_TEST_DATA)
        return file
      end
      
      require 'net/http'

      puts "File #{filename} does not exist. Do you want to download it? (If yes, ~10MB zip file will be downloaded and extracted (to 45MB), if no, very short version .stub file will be used for this test.) y/n?"
      res = gets
      if res.chomp == "y"

        #http://www.phylosoft.org/archaeopteryx/examples/data/tol_life_on_earth_1.xml.zip

        Net::HTTP.start("www.phylosoft.org") { |http|
          resp = http.get("/archaeopteryx/examples/data/tol_life_on_earth_1.xml.zip")
          open("#{file}.zip", "wb") { |f|
            f.write(resp.body)
          }
        }
        #`unzip #{file}.zip -d #{PHYLOXML_TEST_DATA}`
        self.unzip_file(file, PHYLOXML_TEST_DATA)
        puts "File downloaded"
        return file
      else
        return File.join PHYLOXML_TEST_DATA, "#{filename}.stub"
      end
    end

  end

end #end module TestPhyloXMLBigData


module Bio

  class TestPhyloXMLBig < Test::Unit::TestCase


    def test_next_tree
      phyloxml = Bio::PhyloXML::Parser.new(TestPhyloXMLBigData.metazoa_xml)
      #nr_trees = -1
      begin
        tree = phyloxml.next_tree
        #puts nr_trees += 1
      end while tree != nil
    end

    def a_test_next_tree_dummy
      phyloxml = Bio::PhyloXML.new(TestPhyloXMLBigData.metazoa_xml)
      #nr_trees = -1
      puts "metazoa xml"
      begin
        tree = phyloxml.next_tree_dummy
       # puts nr_trees += 1
      end while tree != nil
    end


  end

end
