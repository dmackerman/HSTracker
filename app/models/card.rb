# The Card model
class Card < CDQManagedObject

  attr_accessor :count, :hand_count

  # scope to skip hero and uncollectible cards
  scope :playable, where(collectible: true)
                     .and(:card_type).ne('hero')
                     .and(:card_type).ne('hero power')

  # scope to get only the current locale
  scope :per_lang, where(:lang => Configuration.hearthstone_locale)

  # get a card by its id
  def self.by_id(card_id)
    self.where(card_id: card_id).per_lang.first
  end

  # shortcut to by_name_and_locale for us cards
  def self.by_english_name(name)
    self.by_name_and_locale(name, 'enUS')
  end

  # shortcut to by_name_and_locale for french cards
  def self.by_french_name(name)
    self.by_name_and_locale(name, 'frFR')
  end

  # get a hero by its ID
  def self.hero(card_id)
    self.where(card_id: card_id).per_lang.first
  end

  # get the us name of this card
  def english_name
    if self.lang == 'enUS'
      card = self
    else
      card = Card.where(card_id: card_id, lang: 'enUS').first
    end
    card.name
  end

  # the number of this card we have in our deck
  def count
    @count ||= 1
  end

  # the number of this card we have in hand
  def hand_count
    @hand_count ||= 0
  end

  def is_stolen?
    false
  end

  def is_class_card?
    !player_class.nil?
  end

  def <=>(card)
    Card.compare_card(self, card)
  end

  # sort a deck
  # sort by
  # 1) card cost
  # 2) class card
  # 3) card type (spell, minion, ...)
  # 4) card name
  def self.compare_card(a, b)
    if a.nil?
      1
    elsif b.nil?
      -1
    elsif a.cost != b.cost
      a.cost <=> b.cost
    elsif a.is_class_card? && !b.is_class_card?
      -1
    elsif !a.is_class_card? && b.is_class_card?
      1
    elsif a.card_type != b.card_type
      b.card_type <=> a.card_type
    else
      a.name <=> b.name
    end
  end

  private
  # search a card by a name and locale and return the card in your locale
  def self.by_name_and_locale(name, locale)
    card = self.playable.where(name: name, lang: locale).first
    return nil if card.nil?

    if Configuration.hearthstone_locale == locale
      return card
    end
    self.where(card_id: card.card_id).per_lang.playable.first
  end
end
