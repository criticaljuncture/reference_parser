module ReferenceParser::Registration
  def self.included(base)
    base.extend SetupMethods
  end

  module SetupMethods
    def replacements
      @replacements
    end

    def replace(...)
      @replacements ||= []
      @replacements << ReferenceParser::Replacement.new(...)
    end
  end

  def replacements
    @replacements ||= (self.class.replacements || []).map do |replacement|
      replacement.dup.tap { |duplicate| duplicate.parser = self }
    end
  end
end
