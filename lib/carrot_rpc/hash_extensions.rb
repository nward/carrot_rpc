# Refine the Hash class with new methods and functionality.
module CarrotRpc::HashExtensions
  refine Hash do
    # Utility method to rename keys in a hash
    # @param [String] find the text to look for in a keys
    # @param [String] replace the text to replace the found text
    # @return [Hash] a new hash
    def rename_keys(find, replace, new_hash = {}) # rubocop:disable Metrics/MethodLength
      each do |k, v|
        new_key = k.to_s.gsub(find, replace)

        new_hash[new_key] = if v.is_a? Array
                              v.map { |t| t.rename_keys(find, replace) }
                            elsif v.is_a? Hash
                              v.rename_keys(find, replace)
                            else
                              v
                            end
      end

      new_hash
    end # rubocop:enable Metrics/MethodLength
  end
end
