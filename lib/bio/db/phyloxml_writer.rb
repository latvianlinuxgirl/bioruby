module Bio

  module PhyloXML

    

    class Writer
      #require 'xml/encoding'
      
      attr_accessor :write_branch_length_as_subelement
      
      def initialize(filename, indent=true)
      @write_branch_length_as_subelement = true #default value
      @filename = filename
      @indent = indent
      @doc = XML::Document.new()
      @doc.root = XML::Node.new('phyloxml')
      @root = @doc.root
      @root['xmlns:xsi'] = 'http://www.w3.org/2001/XMLSchema-instance'
      @root['xsi:schemaLocation'] = 'http://www.phyloxml.org http://www.phyloxml.org/1.00/phyloxml.xsd'
      @root['xmlns'] = 'http://www.phyloxml.org'
      #puts XML::LIBXML_VERSION
      #@doc.encoding = XML::Encoding::UTF_8
      @doc.save(@filename, true)
      end

      def write(tree)
        @root << phylogeny = XML::Node.new('phylogeny')        
        
        PhyloXML::Writer.generate_xml(phylogeny, tree, [
            [:attr, 'rooted'],
            [:simple, 'name', tree.name],
            [:complex, 'id', tree.phylogeny_id],
            [:simple, 'description', tree.description],
            #@todo date xs:dateTime
            [:objarr, 'confidence', 'confidences']])

        root_clade = tree.root.to_xml(nil, @write_branch_length_as_subelement)
        phylogeny << root_clade 

        tree.children(tree.root).each do |node|
          root_clade << node_to_xml(tree, node, tree.root)
        end

        Bio::PhyloXML::Writer::generate_xml(phylogeny, tree, [
            [:objarr, 'clade_relation', 'clade_relations'],
            [:objarr, 'sequence_relation', 'sequence_relations'],
            [:objarr, 'property', 'properties']] )

        @doc.save(@filename, @indent)
      end

      def node_to_xml(tree, node, parent)
        edge = tree.get_edge(parent, node)
        branch_length = edge.distance
     
     
        clade = node.to_xml(branch_length, @write_branch_length_as_subelement)

        tree.children(node).each do |new_node|        
          clade << node_to_xml(tree, new_node, node)
        end
       
        return clade
      end

      def write_other(other_arr)
        other_arr.each do |other_obj|
          @root << other_obj.to_xml
        end
        @doc.save(@filename, @indent)
      end

      #class method

      def self.generate_xml(root, elem, subelement_array)
            #[[ :complex,'accession', ], [:simple, 'name',  @name], [:simple, 'location', @location]])
      subelement_array.each do |subelem|
        if subelem[0] == :simple
         # seq << XML::Node.new('name', @name) if @name != nil
          root << XML::Node.new(subelem[1], subelem[2].to_s) if subelem[2] != nil and not subelem[2].to_s.empty?

        elsif subelem[0] == :complex
          root << subelem[2].send("to_xml") if subelem[2] != nil

        elsif subelem[0] == :pattern
          #seq, self, [[:pattern, 'symbol', @symbol, "\S{1,10}"]
          if subelem[2] != nil
            if subelem[2] =~ subelem[3]

              root << XML::Node.new(subelem[1], subelem[2])
            else
              raise "#{subelem[2]} is not a valid value of #{subelem[1]}. It should follow pattern #{subelem[3]}"
            end
          end

        elsif subelem[0] == :objarr
          #[:objarr, 'annotation', 'annotations']])

          obj_arr = elem.send(subelem[2])
          obj_arr.each do |arr_elem|
            root << arr_elem.to_xml
          end

        elsif subelem[0] == :simplearr
          #  [:simplearr, 'common_name', @common_names]
          subelem[2].each do |elem_val|
            root << XML::Node.new(subelem[1], elem_val)
          end
        elsif subelem[0] == :attr
          #[:attr, 'rooted']
          root[subelem[1]] = elem.send(subelem[1]).to_s
        else
          raise "Not supported type of element by method generate_xml."
        end
      end
     end


    end


    class Tree < Bio::Tree

      def write(filename)

        @doc = XML::Document.new()
        @doc.root = XML::Node.new('phyloxml')
        root = @doc.root

        root << clade = XML::Node.new('clade')

        clade << name = XML::Node.new('name')
        name << 'THis is new clade'
#        elem2['attr1'] = 'val1'
#        elem2['attr2'] = 'val2'
#
#        root << elem3 = XML::Node.new('elem3')
#        elem3 << elem4 = XML::Node.new('elem4')
#        elem3 << elem5 = XML::Node.new('elem5')
#
#        elem5 << elem6 = XML::Node.new('elem6')
#        elem6 << 'Content for element 6'
#
#        elem3['attr'] = 'baz'

        @doc.save(filename, true)
        root << clade2 = XML::Node.new('clade')
        clade2 << name2 = XML::Node.new('name')
        name2 << "Second clade"
        @doc.save(filename, true)
      end


    end

  end
end