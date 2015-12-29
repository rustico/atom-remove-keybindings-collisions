removeKeymapSources = (sources) ->
  sources
    .forEach((source) ->
          atom.keymaps.removeBindingsFromSource(source)
    )

addKeybinding = (keybinding) ->
  keyBindingsBySelector = {}
  keyBindingsBySelector[keybinding.selector] = {}
  keyBindingsBySelector[keybinding.selector][keybinding.keystrokes] = keybinding.command
  atom.keymaps.add(keybinding.source,
                   keyBindingsBySelector,
                   keybinding.priority)

sortKeybindings =  (keybindings, exact) ->
  keybindingsSorted = {
    user: {
      keystrokes: {}
    }
    packages: {
      sources: {}
      keybindings: []
    }
  }

  keybindings
    .forEach((keybinding) ->
      source = keybinding.source
      if source.indexOf('keymap.cson') == -1
        keybindingsSorted.packages.sources[source] = true
        keybindingsSorted.packages.keybindings.push(keybinding)
      else
        keybindingKey = getKeybindingKey(keybinding, exact)
        keybindingsSorted.user.keystrokes[keybindingKey] = true
    )

  keybindingsSorted

getKeybindingKey = (keybinding, exact) ->
  if exact
    keybindingKey = keybinding.keystrokes
  else
    keybindingKey = keybinding.keystrokes.split(' ')[0]

removedKeybindings = [];

module.exports = AtomRemoveKeybindingsCollisions =
  config:
    exactKeystrokes:
      type: 'boolean'
      default: false

  activate: (state) ->
    setTimeout(() ->
      keybindings = atom.keymaps.getKeyBindings()
      exact = atom.config.get('atom-remove-keybindings-collisions.exactKeystrokes')
      sortedKeybindings = sortKeybindings(keybindings, exact)
      sources = Object.keys(sortedKeybindings.packages.sources)

      removeKeymapSources(sources)

      sortedKeybindings
        .packages
        .keybindings
        .forEach((keybinding) ->
          keybindingKey = getKeybindingKey(keybinding, exact)
          if not sortedKeybindings.user.keystrokes[keybindingKey]
            addKeybinding(keybinding)
          else
            removedKeybindings.push(keybinding)
        )
    , 100)

  deactivate: ->
    removedKeybindings
    .forEach((keybinding) -> addKeybinding(keybinding))
