Sequel.migration do
  up do
    create_table(:personal_access_tokens) do
      primary_key :id, type: Integer
      foreign_key :account_id, :accounts
      String :digest, null: false
      String :name, null: false
      Time :revoked_at, null: true
      Time :expires_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:personal_access_tokens)
  end
end
