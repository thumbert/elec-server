library client.jokes;

import 'dart:math';

/// Get some jokes to display when waiting from the database.
class Jokes {

  Jokes() {
    random = Random();
  }

  late Random random;

  String next() {
    return list[random.nextInt(list.length)];
  }

  static const list = <String>[
    'People said I\'d never get over my obsession with Phil Collins.  But look '
        'at me now.',
    'Two guys walked into a bar.  The third one ducked',
    'Why was the color green notoriously single?  It was always so jaded',
    'I used to hate facial hair, but then it grew on me',
    'I want to make a brief joke, but it\'s a little cheesy',
    'Dogs can\'t operate MRI machines.  But cats can',
    'Singing in the shower is fun until you get soap in your mouth.  Then it becomes a soap opera',
    'What kind of music chiropractors like?  Hip pop',
    'Why do melons have weddings?  Because they cantaloupe',
    'What did the drummer call his twin daughters?  Anna One, Anna Two',
    'Two goldfish are in a tank.  One says to the other, "Do you know how to drive this thing?"',
    'I didn\'t get a haircut, I got them all cut',
  ];

}