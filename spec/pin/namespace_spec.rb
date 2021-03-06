describe Solargraph::Pin::Namespace do
  # @todo The namespace_pins methods was only ever used in specs.
  it "handles long namespaces" do
    pin = Solargraph::Pin::Namespace.new(nil, 'Foo', 'Bar', '', :class, :public)
    expect(pin.path).to eq('Foo::Bar')
  end

  it "has class scope" do
    source = Solargraph::Source.load_string(%(
      class Foo
      end
    ))
    pin = Solargraph::Pin::Namespace.new(nil, '', 'Foo', '', :class, :public)
    expect(pin.context.scope).to eq(:class)
  end

  it "is a kind of namespace/class/module" do
    pin1 = Solargraph::Pin::Namespace.new(nil, '', 'Foo', '', :class, :public)
    expect(pin1.kind).to eq(Solargraph::Pin::NAMESPACE)
    expect(pin1.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::CLASS)
    pin2 = Solargraph::Pin::Namespace.new(nil, '', 'Foo', '', :module, :public)
    expect(pin2.kind).to eq(Solargraph::Pin::NAMESPACE)
    expect(pin2.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::MODULE)
  end
end
