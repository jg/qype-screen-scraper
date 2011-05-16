Sequel.migration do
	up do
		create_table(:reviews) do
			primary_key :id
			string :body
			string :url
			string :user
			date :date
			integer :rating
			integer :qtype_id
		end
	end


	down do
		drop_table(:reviews)
	end

end
