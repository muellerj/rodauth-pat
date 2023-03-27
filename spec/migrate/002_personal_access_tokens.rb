Sequel.migration do
  up do
    create_table(:personal_access_tokens) do
      foreign_key :id, :accounts, primary_key: true
      String :key, null: false
      # String :scopes
      Time :expires_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:personal_access_tokens)
  end
end
