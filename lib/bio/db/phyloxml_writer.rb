module Bio

  module PhyloXML

    def self.generate_xml(root, elem, subelement_array)
            #[[ :complex,'accession', ], [:simple, 'name',  @name], [:simple, 'location', @location]])
      subelement_array.each do |subelem|
        if subelem[0] == :simple
         # seq << XML::Node.new('name', @name) if @name != nil
          root << XML::Node.new(subelem[1], subelem[2]) if subelem[2] != nil
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
        end
      end


  #      # seq << XML::Node.new('name', @name) if @name != nil
  #      # seq << @accession.to_xml if @accession != nil
  #
  #        seq << XML::Node.new('location', @location) if @location != nil
  #
     end



    class Writer
      def initialize(filename, indent=true)
      @filename = filename
      @indent = true
      @doc = XML::Document.new()
      @doc.root = XML::Node.new('phyloxml')
      @root = @doc.root
      @root['xmlns:xsi'] = 'http://www.w3.org/2001/XMLSchema-instance'
      @root['xsi:schemaLocation'] = 'http://www.phyloxml.org http://www.phyloxml.org/1.00/phyloxml.xsd'
      @root['xmlns'] = 'http://www.phyloxml.org'
      #@root <<  = XML::Node.new('clade')
      @doc.save(@filename, @indent)
      end

      def write(tree, write_branch_length_as_subelement=true)
        @root << phylogeny = XML::Node.new('phylogeny')
        phylogeny['rooted'] = tree.rooted.to_s
        phylogeny << name = XML::Node.new('name', tree.name) if tree.name != nil

        #have to process root node separately because tree.children takes node
        #as a parameter
        phylogeny << XML::Node.new('description', tree.description) unless tree.description == nil

        #Writing root clade
        phylogeny << root_clade = XML::Node.new('clade')
        root_clade << XML::Node.new('name', tree.root.name) if tree.root.name != nil
        if tree.root.taxonomies[0] != nil and tree.root.taxonomies[0].scientific_name != nil
          root_clade << taxonomy = XML::Node.new('taxonomy')
          taxonomy <<  XML::Node.new('scientific_name', tree.root.taxonomies[0].scientific_name) if tree.root.taxonomies != nil
        end
        #IndexError: node1 not found
            #	from /usr/local/lib/site_ruby/1.8/bio/tree.rb:591:in `path'
            #from /usr/local/lib/site_ruby/1.8/bio/tree.rb:640:in `children'

        tree.children(tree.root).each do |node|
          root_clade << node_to_xml(tree, node, tree.root, write_branch_length_as_subelement)
        end


        @doc.save(@filename, @indent)
      end

      def node_to_xml(tree, node, parent, write_branch_length_as_subelement)
        branch_length = tree.get_edge(parent, node).distance
        clade = node.to_xml(branch_length, write_branch_length_as_subelement)

        tree.children(node).each do |new_node|        
          clade << node_to_xml(tree, new_node, node, write_branch_length_as_subelement)
        end
        
        return clade
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