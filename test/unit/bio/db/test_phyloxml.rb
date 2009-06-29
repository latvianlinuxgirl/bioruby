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

#First let's test if xml library is here, since it will be required by bio/db/phyloxml
begin
  require 'xml'
rescue LoadError
  puts "Please install libxml-ruby library. It is needed for Bio::PhyloXML module. Unit tests will exit now."
  #@todo 
  exit 1
end

require 'bio/db/phyloxml'


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

end #end module TestPhyloXMLData


module Bio

#  class TestPhyloXML0 <Test::Unit::TestCase
#    #test if xml lib exists.
#
#    def test_libxml
#      begin
#        require 'xml'
#      rescue LoadError
#        puts "Please install libxml-ruby library. It is needed for Bio::PhyloXML module. Unit tests will exit now."
#        #exit 1
#      end
#    end
#
#  end

  class TestPhyloXML1 < Test::Unit::TestCase
  
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
      assert_equal(node.confidences[0].type, 'bootstrap')
      assert_equal(node.confidences[0].value, 89)
    end

    def test_to_biotreenode_bootstrap
      #iterate throuch first 2 trees to get to the third
      @tree = @phyloxml.next_tree
      @tree = @phyloxml.next_tree
      node = @tree.get_node_by_name("AB")
      bionode = node.to_biotreenode
      assert_equal(bionode.bootstrap, 89)
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
      t = @tree.get_node_by_name('A').taxonomies[0]
      assert_equal(t.scientific_name, 'E. coli')
      t = @tree.get_node_by_name('C').taxonomies[0]
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
        codes[codes.length] = node.taxonomies[0].code
        ids[ids.length] = node.taxonomies[0].taxonomy_id
        #id_types[id_types.length] = node.taxonomy.id_type
      }
      assert_equal(codes.sort, ["CLOAB",  "DICDI", "OCTVU"])
     #@todo assert ids, id_types. or create new class for id.
    end

    def test_taxonomy2
      9.times do
        @tree = @phyloxml.next_tree
      end
      taxonomy = @tree.root.taxonomies[0]
      assert_equal(taxonomy.taxonomy_id.value, "8556")
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
        descrs << node.distributions[0].desc
      }
      assert_equal(descrs.sort, ['Africa', 'Asia', 'Australia'])
    end

    def test_distribution_point
      10.times do
        @tree = @phyloxml.next_tree
      end
      point = @tree.get_node_by_name('A').distributions[0].points[0]
      assert_equal(point.geodetic_datum, "WGS84")
      assert_equal(point.lat, 47.481277)
      assert_equal(point.long, 8.769303)
      assert_equal(point.alt,472)

      point = @tree.get_node_by_name('B').distributions[0].points[0]
      assert_equal(point.geodetic_datum, "WGS84")
      assert_equal(point.lat, 35.155904)
      assert_equal(point.long, 136.915863)
      assert_equal(point.alt,10)
    end

    def test_sequence
      3.times do
        @tree = @phyloxml.next_tree
      end
      sequence_a = @tree.get_node_by_name('A').sequences[0]
      assert_equal(sequence_a.annotations[0].desc, 'alcohol dehydrogenase')
      assert_equal(sequence_a.annotations[0].confidence.type, "probability" )
      assert_equal(sequence_a.annotations[0].confidence.value, 0.99 )
      sequence_b = @tree.get_node_by_name('B').sequences[0]
      assert_equal(sequence_b.annotations[0].desc, 'alcohol dehydrogenase')
      assert_equal(sequence_b.annotations[0].confidence.type, "probability" )
      assert_equal(sequence_b.annotations[0].confidence.value, 0.91 )
      sequence_c = @tree.get_node_by_name('C').sequences[0]
      assert_equal(sequence_c.annotations[0].desc, 'alcohol dehydrogenase')
      assert_equal(sequence_c.annotations[0].confidence.type, "probability" )
      assert_equal(sequence_c.annotations[0].confidence.value, 0.67 )

    end

     def test_sequence2
       4.times do
         @tree = @phyloxml.next_tree
       end
       leaves = @tree.leaves
       leaves.each { |node|
         #just test one node for now
         if node.sequences[0].id_source == 'x'
           assert_equal(node.sequences[0].symbol, 'adhB')
           assert_equal(node.sequences[0].accession.source, "ncbi")
           assert_equal(node.sequences[0].accession.value, 'AAB80874')
           assert_equal(node.sequences[0].name, 'alcohol dehydrogenase')
         end
         if node.sequences[0].id_source == 'z'
           assert_equal(node.sequences[0].annotations[0].ref, "InterPro:IPR002085")
         end
       }
     end

     def test_sequence3
       5.times do
         @tree = @phyloxml.next_tree
       end
       @tree.leaves.each { |node|
         if node.sequences[0].symbol == 'ADHX'
          assert_equal(node.sequences[0].accession.source, 'UniProtKB')
          assert_equal(node.sequences[0].accession.value, 'P81431')
          assert_equal(node.sequences[0].name, 'Alcohol dehydrogenase class-3')
          assert_equal(node.sequences[0].mol_seq, 'TDATGKPIKCMAAIAWEAKKPLSIEEVEVAPPKSGEVRIKILHSGVCHTD')
          assert_equal(node.sequences[0].annotations[0].ref, 'EC:1.1.1.1')
          assert_equal(node.sequences[0].annotations[1].ref, 'GO:0004022')
         end
       }
     end

     def test_to_biosequence
       5.times do
         @tree = @phyloxml.next_tree
       end
       @tree.leaves.each { |node|
         if node.sequences[0].symbol =='ADHX'
           seq = node.sequences[0].to_biosequence
           assert_equal(seq.definition, 'Alcohol dehydrogenase class-3')
           assert_equal(seq.id_namespace, 'UniProtKB' )
           assert_equal(seq.entry_id, 'P81431')
           assert_equal(seq.seq.to_s, 'TDATGKPIKCMAAIAWEAKKPLSIEEVEVAPPKSGEVRIKILHSGVCHTD')
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
       property = @tree.get_node_by_name('A').properties[0]
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

    def test_polygon
      2.times do
        @tree = @phyloxml.next_tree
      end
      polygon = @tree.get_node_by_name('A').distributions[0].polygons[0]
      assert_equal(polygon.points.length,3 )
      assert_equal(polygon.points[0].lat, 47.481277)
      assert_equal(polygon.points[1].long, 136.915863)
      assert_equal(polygon.points[2].alt, 452)
      polygon = @tree.get_node_by_name('A').distributions[0].polygons[1]
      #making sure can read in second polygon
      assert_equal(polygon.points.length,3 )
      assert_equal(polygon.points[0].lat, 40.481277)
    end

    def test_reference
      3.times do
        @tree = @phyloxml.next_tree
        #puts "tree name: " ,@tree.name
      end
      references = @tree.get_node_by_name('A').references
      assert_equal(references[0].doi, "10.1093/bioinformatics/btm619")
      assert_equal(references[0].desc, "Phyutility: a phyloinformatics tool for trees, alignments and molecular data")
      assert_equal(references[1].doi, "10.1186/1471-2105-9-S1-S23")
    end


    def test_single_clade

      3.times do
        @tree = @phyloxml.next_tree()
      end
      @tree = @phyloxml.next_tree()
      assert_equal(@tree.root.name, "A")
    end
  end

#  class TestPhyloXMLBigFiles < Test::Unit::TestCase
#
#
#    def test_next_tree_big_file()
#      @phyloxml = Bio::PhyloXML.new(TestPhyloXMLData.metazoa_xml)
#      tree = @phyloxml.next_tree
#      while tree != nil do
#        tree = @phyloxml.next_tree
#        puts tree.root.name
#      end
#    end
#
#    def test_next_tree_big_file2()
#      puts "====="
#      @phyloxml = Bio::PhyloXML.new(TestPhyloXMLData.mollusca_xml)
#      tree = @phyloxml.next_tree
#      while tree != nil do
#        tree = @phyloxml.next_tree
#        puts tree.root.name
#      end
#    end
#
#    def test_next_tree_big_file3()
#      @phyloxml = Bio::PhyloXML.new(TestPhyloXMLData.life_xml)
#      tree = @phyloxml.next_tree
#      while tree != nil do
#        tree = @phyloxml.next_tree
#        puts tree.root.name
#      end
#    end
#
#  end #class TestPhyloXML


end #end module Bio
