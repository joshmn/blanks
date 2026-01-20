# Blanks

_fill it in_.

Blanks is a form object pattern that works with Rails form helpers and validations without requiring database persistence.

Most forms don't map to a single database table; some don't map to the database at all. This gem provides form objects that implement the ActiveModel interface—associations, validations, nested attributes, dirty tracking—without requiring ActiveRecord.

Built on ActiveModel, so the Rails conventions you already know work here. Use the same validations, callbacks, attribute types, and form helpers. Forms integrate with `form_with` and `fields_for` without configuration. Error handling, i18n, dirty tracking, and model naming all follow standard Rails patterns.

## Installation

You've done this before:

```ruby
gem 'blanks'
```


## Usage

### Basic form with attributes

```ruby
class PostForm < Blanks::Base
  attribute :title, :string
  attribute :content, :string
  attribute :created_at, :datetime, default: -> { Time.current }

  validates :title, presence: true
  validates :content, presence: true
  validates :created_at, presence: true
end

form = PostForm.new(title: "hello", content: "world")
form.valid? # true
```

### Inheriting attributes from models

Pull attribute definitions from existing models instead of manually defining each one.

```bash
rails g model Post title:string content:text
```

```ruby
class Post < ApplicationRecord; end

class PostForm < Blanks::Base
  inherit_attributes_from Post, except: [:created_at, :updated_at]
end
```

Use `only:` to include specific attributes:

```ruby
class PostForm < Blanks::Base
  inherit_attributes_from Post, only: [:title, :content]
end
```

Inherited attributes work with `from_model` and preserve the model's attribute types.

### Inheriting validations from models

Copy validation rules from existing models.

```ruby
class Post < ApplicationRecord
  validates :title, presence: true, length: { minimum: 3 }
  validates :content, presence: true
end

class PostForm < Blanks::Base
  inherit_attributes_from Post, only: [:title, :content]
  inherit_validations_from Post, only: [:title]

  validates :content, presence: true, length: { minimum: 50 }
end
```

Use `only:` and `except:` to control which validations are inherited.

#### What doesn't copy

Some validators are skipped because they don't translate cleanly to form objects:

**Proc/lambda conditionals** - Validators with `if: -> { ... }` or `unless: -> { ... }` are skipped. The closure captures the source class context and won't work correctly on the form.

```ruby
validates :content, presence: true, if: -> { published? }
```

**Symbol conditionals** work fine, but the form must define the method:

```ruby
validates :content, presence: true, if: :published?

def published?
  status == "published"
end
```

**Association validators** - `validates_associated` references ActiveRecord associations that don't exist on forms. These are always skipped.

**Custom validators** work if they're `EachValidator` subclasses. Validators that call methods specific to the source model will fail at runtime.

**Missing attributes** - If you inherit a validation for an attribute that doesn't exist on the form, it will raise at runtime. Use `inherit_attributes_from` first or define the attribute manually.

### Associations

```ruby
class ImageForm < Blanks::Base
  attribute :url, :string
  validates :url, presence: true
end

class PostForm < Blanks::Base
  has_one :cover_photo  # defaults to CoverPhotoForm
  has_many :images      # defaults to ImageForm

  attribute :title, :string
  validates :title, presence: true
end

form = PostForm.new
form.images.new(url: "https://example.com/image.jpg")
form.images.count # 1
```

### Nested attributes from params

```ruby
params = {
  title: "hello",
  cover_photo_attributes: { url: "https://example.com/cover.jpg" },
  images_attributes: [
    { url: "https://example.com/1.jpg" },
    { url: "https://example.com/2.jpg" }
  ]
}

form = PostForm.new(params)
form.cover_photo.url # "https://example.com/cover.jpg"
form.images.count # 2
```

### Load from model

Class method creates a new instance:

```ruby
post = Post.find(1)
form = PostForm.from_model(post)

form.title # value from post
form.cover_photo.url # value from post.cover_photo
form.images.count # post.images.count
```

Instance method for existing forms:

```ruby
form = PostForm.new
form.from_model(post)
```

### Validation with nested forms

Validations automatically cascade to nested forms:

```ruby
form = PostForm.new(title: "hello")
form.images.new(url: nil) # invalid image

form.valid? # false
form.errors.full_messages # includes nested form errors
```

### Extracting attributes for persistence

Use `model_attributes` for the form's own attributes:

```ruby
form = PostForm.new(title: "test")
form.model_attributes # => { "title" => "test", "content" => nil }

Post.create!(form.model_attributes)
```

Use `attributes` for all attributes including nested:

```ruby
form = PostForm.new(
  title: "test",
  images_attributes: [{ url: "image.jpg" }]
)

form.attributes
# => {
#   "title" => "test",
#   "content" => nil,
#   "images_attributes" => [{ "url" => "image.jpg" }]
# }

Post.create!(form.attributes) # works with accepts_nested_attributes_for
```

### ID tracking in nested forms

When editing existing records, nested forms update by id:

```ruby
post = Post.find(1) # has images with id: 1, 2, 3
form = PostForm.from_model(post)

form.images_attributes = [
  { id: 1, url: "updated.jpg" },  # updates existing
  { url: "new.jpg" }               # creates new
]

form.images.count # 4 (3 original + 1 new)
form.images[0].url # "updated.jpg"
```

Use `primary_key` option for non-id identifiers:

```ruby
class ImageForm < Blanks::Base
  attribute :uuid, :string
  attribute :url, :string
end

class PostForm < Blanks::Base
  has_many :images, primary_key: :uuid
end

form = PostForm.new
form.images.new(uuid: "abc-123", url: "original.jpg")

form.images_attributes = [
  { uuid: "abc-123", url: "updated.jpg" }  # updates by uuid
]

form.images.first.url # "updated.jpg"
```

Works with `has_one` and `has_many`. Defaults to `:id`.

### Destroying nested forms

Mark nested records for deletion with `allow_destroy: true`:

```ruby
class PostForm < Blanks::Base
  has_many :images, allow_destroy: true
end

post = Post.find(1) # has images with id: 1, 2, 3
form = PostForm.from_model(post)

form.images_attributes = [
  { id: 1, url: "updated.jpg" },  # updates existing
  { id: 2, _destroy: true },      # marks for deletion
  { url: "new.jpg" }               # creates new
]

form.images[1].marked_for_destruction? # true
form.attributes["images_attributes"][1]["_destroy"] # true
```

When extracting attributes, records marked for destruction include `_destroy: true`. Works with has_one and has_many.

### Dirty tracking

Track attribute changes:

```ruby
form = PostForm.new(title: "original")
form.title = "changed"

form.title_changed? # true
form.title_was # "original"
form.changes # { "title" => ["original", "changed"] }
```

### Normalization

Normalize attribute values on assignment. Works on Rails 6+, not just 7.1+.

Normalization is idempotent—applying it multiple times produces the same result as applying it once.

```ruby
class UserForm < Blanks::Base
  attribute :email, :string
  attribute :phone, :string

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :phone, with: ->(phone) { phone.delete("^0-9").delete_prefix("1") }
end

form = UserForm.new(email: " TEST@EXAMPLE.COM\n")
form.email # "test@example.com"

form = UserForm.new(phone: "1-555-123-4567")
form.phone # "5551234567"
```

Normalize multiple attributes with one call:

```ruby
class PostForm < Blanks::Base
  attribute :title, :string
  attribute :author, :string

  normalizes :title, :author, with: ->(value) { value.strip }
end
```

By default, normalization skips nil values. Override with `apply_to_nil: true`:

```ruby
normalizes :email, with: ->(email) { email || "default@example.com" }, apply_to_nil: true
```

### Callbacks

Hook into the validation lifecycle:

```ruby
class PostForm < Blanks::Base
  attribute :title, :string

  before_validation :normalize_title
  after_validation :log_errors

  def normalize_title
    self.title = title&.strip&.downcase
  end

  def log_errors
    Rails.logger.error(errors.full_messages) if errors.any?
  end
end
```

### Rails form integration

#### model naming

Form classes automatically strip the "Form" suffix for Rails form helpers:

```ruby
class PostForm < Blanks::Base
  attribute :title, :string
end

form = PostForm.new
form.model_name.param_key # "post"
# rails generates: <input name="post[title]">
```

Override when needed:

```ruby
class AdminArticleForm < Blanks::Base
  model_name_for :article
end

form.model_name.param_key # "article"
```

#### persistence detection

Forms automatically detect persistence via the `id` attribute:

```ruby
class PostForm < Blanks::Base
  attribute :id, :integer
  attribute :title, :string
end

form = PostForm.new
form.persisted? # false

form = PostForm.new(id: 123)
form.persisted? # true
form.to_param # "123"
```

Override for custom logic:

```ruby
class PostForm < Blanks::Base
  def persisted?
    # custom logic
  end

  def to_param
    # custom logic
  end
end
```

#### i18n

Standard ActiveModel translation support:

```yaml
# config/locales/en.yml
en:
  activemodel:
    attributes:
      post:  # uses model_name, not PostForm
        title: "Post Title"
    errors:
      models:
        post:
          attributes:
            title:
              blank: "must be provided"
```

## License

MIT.
