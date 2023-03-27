Sequel.migration do
  up do
    extension :date_arithmetic

    create_table(:accounts) do
      primary_key :id, type: Integer
      String :email, null: false
      index :email, unique: true
    end
  end

  down do
    drop_table(:accounts, :account_statuses)
  end
end
