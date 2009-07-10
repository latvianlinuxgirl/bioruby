module Bio

  module PhyloXML

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

      def write(tree)
        @root << phylogeny = XML::Node.new('phylogeny')
        phylogeny['rooted'] = tree.rooted.to_s
        phylogeny << name = XML::Node.new('name', tree.name) if tree.name != nil

        #have to process root node separately because tree.children takes node
        #as a parameter
        phylogeny << root_clade = XML::Node.new('clade')
        root_clade << XML::Node.new('name', tree.root.name) if tree.root.name != nil
        #if node.taxonomies[0] != nil and node.taxonomies[0].scientific_name != nil)
          root_clade << taxonomy = XML::Node.new('taxonomy')
          taxonomy << scientific_name = XML::Node.new('scientific_name', tree.root.taxonomies[0].scientific_name) if tree.root.taxonomies != nil

        tree.children(tree.root).each do |node|
          root_clade << node_to_xml(tree, node)
        end


        @doc.save(@filename, @indent)
      end

      def node_to_xml(tree, node)
        clade = XML::Node.new('clade')
        clade << XML::Node.new('name', node.name) if node.name != nil
        if (node.taxonomies[0] != nil and node.taxonomies[0].scientific_name != nil)
          clade << taxonomy = XML::Node.new('taxonomy')
          taxonomy << XML::Node.new('scientific_name', node.taxonomies[0].scientific_name)
        end


        tree.children(node).each do |new_node|        
          clade << node_to_xml(tree, new_node)
        end
        
        return clade
      end

      def node_elements_to_xml(node)

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