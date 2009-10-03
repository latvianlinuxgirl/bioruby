require 'pathname'
libpath = Pathname.new(File.join(File.dirname(__FILE__), '..', 'lib')).cleanpath.to_s
$:.unshift(libpath) unless $:.include?(libpath)

require 'bio'



fn = ARGV[0]
if fn.nil?
       fn = File.join(File.dirname(__FILE__),'../test/data/phyloxml/ncbi_taxonomy_mollusca.xml')
end

puts "Started: " + Time.now.to_s

p = Bio::PhyloXML::Parser.new(fn)

tree1 = p.next_tree

swr = Time.now
puts "Finished reading file. Now writing: " + swr.to_s

writer = Bio::PhyloXML::Writer.new('test_phyloxml_output.xml')

writer.write(tree1)

fwr = Time.now
puts "Finished writing: " + fwr.to_s

print "Time elapsed to write a file: ", fwr-swr,  " s\n"
