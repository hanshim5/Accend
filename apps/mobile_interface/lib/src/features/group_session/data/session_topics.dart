/// A fixed pool of topics passed to the AI when generating group session items.
///
/// One topic is picked at random each time a lobby host starts a session.
/// Topics are intentionally broad so the AI has room to produce varied,
/// natural-sounding phrases that are good for pronunciation practice.
const List<String> kSessionTopics = [
  'Daily routines',
  'Food and restaurants',
  'Travel and transportation',
  'Work and careers',
  'Weather and seasons',
  'Health and fitness',
  'Shopping and money',
  'Family and relationships',
  'Hobbies and free time',
  'Technology and gadgets',
  'Nature and the environment',
  'Sports and games',
  'Education and learning',
  'Movies and entertainment',
  'Cooking and recipes',
  'Housing and home life',
  'Cities and neighborhoods',
  'Social events and celebrations',
  'News and current affairs',
  'Animals and pets',
];
