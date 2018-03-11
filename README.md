# <img src="https://v20.imgup.net/oakdex_logfbad.png" alt="fixer" width=282>

[![Build Status](https://travis-ci.org/jalyna/oakdex-battle.svg?branch=master)](https://travis-ci.org/jalyna/oakdex-battle) [![Maintainability](https://api.codeclimate.com/v1/badges/ef91681257a6900f03ac/maintainability)](https://codeclimate.com/github/jalyna/oakdex-battle/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/ef91681257a6900f03ac/test_coverage)](https://codeclimate.com/github/jalyna/oakdex-battle/test_coverage)

Based on [oakdex-pokedex](https://github.com/jalyna/oakdex-pokedex).

## Getting Started

### 1 vs. 1

```ruby
require 'oakdex/battle'

pok1 = Oakdex::Battle::Pokemon.create('Pikachu', level: 10)
pok2 = Oakdex::Battle::Pokemon.create('Bulbasaur', {
  exp: 120,
  gender: 'female',
  ability: 'Soundproof',
  nature: 'Bashful',
  item: 'Earth Plate',
  hp: 2,
  iv: {
    hp: 8,
    atk: 12,
    def: 31,
    sp_atk: 12,
    sp_def: 5,
    speed: 14
  },
  ev: {
    hp: 8,
    atk: 12,
    def: 99,
    sp_atk: 4,
    sp_def: 12,
    speed: 14
  },
  moves: [
    ['Swords Dance', 12, 30],
    ['Cut', 40, 44]
  ]
})

trainer1 = Oakdex::Battle::Trainer.new('Ash', [pok1])
trainer2 = Oakdex::Battle::Trainer.new('Misty', [pok2])

battle = Oakdex::Battle.new(trainer1, trainer2)
battle.continue # => true
battle.log.size # => 1
battle.log.last # => [['sends_to_battle', 'Ash', 'Pikachu'], ['sends_to_battle', 'Misty', 'Bulbasaur']]
battle.arena # => Snapshot of current state as Hash
battle.finished? # => false
battle.valid_actions_for(trainer1) # => [{ action: 'move', pokemon: pok1, move: 'Thunder Shock', target: pok2 }, ...]

battle.add_action(trainer1, { action: 'move', pokemon: pok1, move: 'Thunder Storm', target: pok2 }) # => false

battle.add_action(trainer1, { action: 'move', pokemon: pok1, move: 'Thunder Shock', target: pok2 }) # => true

battle.valid_actions_for(trainer1) # => []
battle.continue # => false
battle.simulate_action(trainer2) # => true
battle.valid_actions_for(trainer2) # => []
battle.continue # => true

battle.log.size # => 2
battle.log.last # => [['uses_move', 'Ash', 'Pikachu', 'Thunder Shock'], ['received_damage', 'Misty', 'Bulbasaur', 'Thunder Shock'], ['uses_move', 'Misty', 'Bulbasaur', 'Leech Seed'], ['move_failed', 'Misty', 'Bulbasaur', 'Leech Seed']]

# ...

battle.finished? # => true
battle.winner # => trainer1
```


### Other Battle types

```ruby
pok3 = Oakdex::Battle::Pokemon.create('Altaria', level: 20)
pok4 = Oakdex::Battle::Pokemon.create('Elekid', level: 14)
trainer3 = Oakdex::Battle::Trainer.new('Jessie', [pok3])
trainer4 = Oakdex::Battle::Trainer.new('James', [pok4])

battle2 = Oakdex::Battle.new([trainer1, trainer3], [trainer2, trainer4], type: :double)

battle = Oakdex::Battle.new([trainer1], [trainer2]) # 1v1
battle = Oakdex::Battle.new([trainer1], [trainer2], type: :double)
battle = Oakdex::Battle.new([trainer1], [trainer2], type: :triple)
battle = Oakdex::Battle.new([trainer1], [trainer2], type: :horde)
```


## Contributing

I would be happy if you want to add your contribution to the project. In order to contribute, you just have to fork this repository.

## License

MIT License. See the included MIT-LICENSE file.

## Credits

Logo Icon by [Roundicons Freebies](http://www.flaticon.com/authors/roundicons-freebies).
