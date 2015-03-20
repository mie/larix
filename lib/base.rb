module Larix

  module Base

    def inst_vars(hash)
      hash.each{ |k,v|
        name = "@#{k.downcase}"
        instance_variable_set(name, v)
        self.class.send(:define_method, k.downcase) do
          instance_variable_get(name)
        end
      }
    end

    def save(path, contents)
      File.open(File.expand_path(path), "w:UTF-8") { |f|  f.write(contents) }
      path
    end

    def clear
      Dir.glob(File.join(@root, @output, '**', '*.*')) do |f|
        File.delete(f) if File.file?(f) and f != '.' and f != '..'
      end
      Dir.glob(File.join(@root, @output, '**', '*')) do |d|
        FileUtils.remove_dir(d) if File.directory?(d) and d != '.' and d != '..'
      end
    end

    def copy_assets
      theme = File.join(@root, @themes, @theme)
      Dir.chdir(theme)
      Dir['*/'].each { |catalog|
        FileUtils.copy_entry(File.join(theme, catalog), File.join(@static_dir, catalog))
      }
      FileUtils.copy_entry(File.join(@source_dir, 'images'), File.join(@static_dir, 'images'))
    end

    refine Array do

      def split_by(key,per_page=nil)
        out = {}
        self.each do |e|
          if e.class == Post
            v = e.send("#{key}")
            existing = out.keys.select{|k| k == v}
            found = existing[0] if existing.size > 0
            if found
              out[found].push(e)
            else
              out[v] = [e]
            end
          end
        end
        out.keys.each do |k|
          out[k] = out[k].sort!.each_slice(per_page).to_a
        end if per_page
        out
      end

    end

  end

end