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

  def self.made_up_xml
    File.join TEST_DATA, 'made_up.xml'
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
      
    def test_next_tree()
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

    def test_taxonomy2
      9.times do
        @tree = @phyloxml.next_tree
      end
      taxonomy = @tree.root.taxonomy[0]
      assert_equal(taxonomy.id.type, "NCBI")
      assert_equal(taxonomy.id.value, "8556")
      assert_equal(taxonomy.scientific_name, "Varanus")
      assert_equal(taxonomy.rank, "genus")
      assert_equal(taxonomy.uri.desc, "EMBL REPTILE DATABASE")
      assert_equal(taxonomy.uri.uri, "http://www.embl-heidelberg.de/~uetz/families/Varanidae.html")
    end

    def test_distribution_desc
      9.times do
        @tree = @phyloxml.next_tree
      end
      leaves = @tree.leaves
      descrs = []
      leaves.each { |node|
        descrs[descrs.length] = node.distribution[0].desc
      }
      assert_equal(descrs.sort, ['Africa', 'Asia', 'Australia'])
    end

    def test_distribution_point
      10.times do
        @tree = @phyloxml.next_tree
      end
      point = @tree.get_node_by_name('A').distribution[0].points[0]
      assert_equal(point.geodetic_datum, "WGS84")
      assert_equal(point.lat, 47.481277)
      assert_equal(point.long, 8.769303)
      assert_equal(point.alt[0],472)

      point = @tree.get_node_by_name('B').distribution[0].points[0]
      assert_equal(point.geodetic_datum, "WGS84")
      assert_equal(point.lat, 35.155904)
      assert_equal(point.long, 136.915863)
      assert_equal(point.alt[0],10)
    end

    def test_sequence
      3.times do
        @tree = @phyloxml.next_tree
      end
      sequence_a = @tree.get_node_by_name('A').sequence[0]
      assert_equal(sequence_a.annotation[0].desc, 'alcohol dehydrogenase')
      assert_equal(sequence_a.annotation[0].confidence.type, "probability" )
      assert_equal(sequence_a.annotation[0].confidence.value, 0.99 )
      sequence_b = @tree.get_node_by_name('B').sequence[0]
      assert_equal(sequence_b.annotation[0].desc, 'alcohol dehydrogenase')
      assert_equal(sequence_b.annotation[0].confidence.type, "probability" )
      assert_equal(sequence_b.annotation[0].confidence.value, 0.91 )
      sequence_c = @tree.get_node_by_name('C').sequence[0]
      assert_equal(sequence_c.annotation[0].desc, 'alcohol dehydrogenase')
      assert_equal(sequence_c.annotation[0].confidence.type, "probability" )
      assert_equal(sequence_c.annotation[0].confidence.value, 0.67 )

    end

     def test_sequence2
       4.times do
         @tree = @phyloxml.next_tree
       end
       leaves = @tree.leaves
       leaves.each { |node|
         #just test one node for now
         if node.sequence[0].id_source == 'x'
           assert_equal(node.sequence[0].symbol, 'adhB')
           assert_equal(node.sequence[0].accession.source, "ncbi")
           assert_equal(node.sequence[0].accession.value, 'AAB80874')
           assert_equal(node.sequence[0].name, 'alcohol dehydrogenase')
         end
         if node.sequence[0].id_source == 'z'
           assert_equal(node.sequence[0].annotation[0].ref, "InterPro:IPR002085")
         end
       }
     end

     def test_sequence3
       5.times do
         @tree = @phyloxml.next_tree
       end
       @tree.leaves.each { |node|
         if node.sequence[0].symbol == 'ADHX'
          assert_equal(node.sequence[0].accession.source, 'UniProtKB')
          assert_equal(node.sequence[0].accession.value, 'P81431')
          assert_equal(node.sequence[0].name, 'Alcohol dehydrogenase class-3')
          assert_equal(node.sequence[0].mol_seq, 'TDATGKPIKCMAAIAWEAKKPLSIEEVEVAPPKSGEVRIKILHSGVCHTD')
          assert_equal(node.sequence[0].annotation[0].ref, 'EC:1.1.1.1')
          assert_equal(node.sequence[0].annotation[1].ref, 'GO:0004022')
         end
       }
     end

     def test_date
       11.times do
         @tree = @phyloxml.next_tree
       end
       date_a = @tree.get_node_by_name('A').date
       assert_equal(date_a.unit, 'mya')
       assert_equal(date_a.range, 10)
       assert_equal(date_a.desc, "Silurian")
       assert_equal(date_a.value, 425)
       date_b = @tree.get_node_by_name('B').date
       assert_equal(date_b.unit, 'mya')
       assert_equal(date_b.range, 20)
       assert_equal(date_b.desc, "Devonian")
       assert_equal(date_b.value, 320)
       date_c = @tree.get_node_by_name('C').date
       assert_equal(date_c.unit, 'mya')
       assert_equal(date_c.range, 30)
       assert_equal(date_c.desc, 'Ediacaran')
       assert_equal(date_c.value, 600)
     end

     def test_property
       7.times do
         @tree = @phyloxml.next_tree
       end
       property = @tree.get_node_by_name('A').property[0]
       assert_equal(property.datatype, 'xsd:integer')
       assert_equal(property.ref,'NOAA:depth')
       assert_equal(property.applies_to, 'clade')
       assert_equal(property.unit, 'METRIC:m')
       assert_equal(property.value, ' 1200 ')
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
      @tree.children(node).each { |children|
        node_names[node_names.length] = children.name
      }
      node_names.sort!
      assert_equal(node_names, ["A", "B"])
    end

  
  end # class

  class TestPhyloXML4 < Test::Unit::TestCase

    #test cases what pertain to tree

    def test_clade_relation

      @phyloxml = Bio::PhyloXML.new(TestPhyloXMLData.example_xml)
      7.times do
        @tree = @phyloxml.next_tree
      end
      #puts @tree.name
       #<clade_relation id_ref_0="b" id_ref_1="c" type="network_connection"/>
       cr = @tree.clade_relations[0]
       assert_equal(cr.id_ref_0, "b")
       assert_equal(cr.id_ref_1, "c")
       assert_equal(cr.type, "network_connection")
    end

    def test_sequence_realations
      @phyloxml = Bio::PhyloXML.new(TestPhyloXMLData.example_xml)
      5.times do
        @tree = @phyloxml.next_tree
      end
      #<sequence_relation id_ref_0="x" id_ref_1="y" type="paralogy"/>
      #<sequence_relation id_ref_0="x" id_ref_1="z" type="orthology"/>
      #<sequence_relation id_ref_0="y" id_ref_1="z" type="orthology"/>

      sr = @tree.sequence_relations[0]
       
       assert_equal(sr.id_ref_0, "x")
       assert_equal(sr.id_ref_1, "y")
       assert_equal(sr.type, "paralogy")

    end
  end

  class TestPhyloXML5 < Test::Unit::TestCase

    #testing file random.xml
    def setup
      @phyloxml = Bio::PhyloXML.new(TestPhyloXMLData.made_up_xml)
    end

    def test_phylogeny_confidence
      tree = @phyloxml.next_tree()
      assert_equal(tree.confidences[0].type, "bootstrap")
      assert_equal(tree.confidences[0].value, 89)
      assert_equal(tree.confidences[1].type, "probability")
      assert_equal(tree.confidences[1].value, 0.71)
    end

    def test_single_clade
      2.times do
        @tree = @phyloxml.next_tree()
      end
      assert_equal(@tree.root.name, "A")
    end

  end

end #end module Bio
