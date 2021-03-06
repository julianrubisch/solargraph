describe Solargraph::Pin::Method do
  it "tracks code parameters" do
    source = Solargraph::Source.new(%(
      def foo bar, baz = MyClass.new
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.select{|pin| pin.path == '#foo'}.first
    expect(pin.parameters.length).to eq(2)
    expect(pin.parameters[0]).to eq('bar')
    expect(pin.parameters[1]).to eq('baz = MyClass.new')
    expect(pin.parameter_names).to eq(%w[bar baz])
  end

  it "tracks keyword parameters" do
    source = Solargraph::Source.new(%(
      def foo bar:, baz: MyClass.new
      end
    ))
    map = Solargraph::SourceMap.map(source)
    pin = map.pins.select{|pin| pin.path == '#foo'}.first
    expect(pin.parameters.length).to eq(2)
    expect(pin.parameters[0]).to eq('bar:')
    expect(pin.parameters[1]).to eq('baz: MyClass.new')
    expect(pin.parameter_names).to eq(%w[bar baz])
  end

  it "includes param tags in documentation" do
    comments = %(
      @param one [First] description1
      @param two [Second] description2
    )
    # pin = source.pins.select{|pin| pin.path == 'Foo#bar'}.first
    pin = Solargraph::Pin::Method.new(nil, nil, nil, comments, nil, nil, [])
    expect(pin.documentation).to include('one')
    expect(pin.documentation).to include('[First]')
    expect(pin.documentation).to include('description1')
    expect(pin.documentation).to include('two')
    expect(pin.documentation).to include('[Second]')
    expect(pin.documentation).to include('description2')
  end

  it "detects return types from tags" do
    pin = Solargraph::Pin::Method.new(nil, nil, nil, '@return [Hash]', nil, nil, [])
    expect(pin.return_type.tag).to eq('Hash')
  end

  it "ignores malformed return tags" do
    pin = Solargraph::Pin::Method.new(nil, 'Foo', 'bar', '@return [Array<String', :instance, :public, [])
    expect(pin.return_complex_type).to be_undefined
  end

  it "will not merge with changes in parameters" do
    pin1 = Solargraph::Pin::Method.new(nil, 'Foo', 'bar', '', :instance, :public, ['one', 'two'])
    pin2 = Solargraph::Pin::Method.new(nil, 'Foo', 'bar', '', :instance, :public, ['three'])
    expect(pin1.nearly?(pin2)).to be(false)
  end

  it "adds param tags to documentation" do
    pin = Solargraph::Pin::Method.new(nil, 'Foo', 'bar', '@param one [String]', :instance, :public, ['*args'])
    expect(pin.documentation).to include('one', '[String]')
  end

  it "infers return types from reference tags" do
    source = Solargraph::Source.load_string(%(
      class Foo1
        # @return [Hash]
        def bar; end
      end

      class Foo2
        # @return (see Foo1#bar)
        def baz; end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.get_path_pins('Foo2#baz').first
    type = pin.typify(api_map)
    expect(type.tag).to eq('Hash')
  end

  it "infers return types from relative reference tags" do
    source = Solargraph::Source.load_string(%(
      module Container
        class Foo1
          # @return [Hash]
          def bar; end
        end

        class Foo2
          # @return (see Foo1#bar)
          def baz; end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.get_path_pins('Container::Foo2#baz').first
    type = pin.typify(api_map)
    expect(type.tag).to eq('Hash')
  end

  it "infers return types from method reference tags" do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @return [Hash]
        def bar; end
        # @return (see #bar)
        def baz; end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.get_path_pins('Foo#baz').first
    type = pin.typify(api_map)
    expect(type.tag).to eq('Hash')
  end

  it "infers return types from top-level reference tags" do
    source = Solargraph::Source.load_string(%(
      class Other
        # @return [Hash]
        def origin; end
      end
      class Foo
        # (see Other#origin)
        def bar; end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.get_path_pins('Foo#bar').first
    type = pin.typify(api_map)
    expect(type.tag).to eq('Hash')
  end

  it "typifies Booleans" do
    pin = Solargraph::Pin::Method.new(nil, '', 'foo', '@return [Boolean]', :instance, :public, [])
    api_map = Solargraph::ApiMap.new
    type = pin.typify(api_map)
    expect(type.tag).to eq('Boolean')
  end
end
