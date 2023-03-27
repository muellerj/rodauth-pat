Sequel.migration do
  up do
    create_table(:personal_access_tokens) do
      foreign_key :id, :accounts, primary_key: true, type: :primary_key_type
      String :key, null: false
      # String :scopes
      Time :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:personal_access_tokens)
  end
end
