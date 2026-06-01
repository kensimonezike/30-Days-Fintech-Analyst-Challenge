-- Create and populate the customers table

CREATE TABLE customers (
    customer_id         VARCHAR(20) PRIMARY KEY,
    user_id             VARCHAR(20) UNIQUE,
    full_name           VARCHAR(100),
    account_tier        VARCHAR(20),
    signup_date         DATE,
    city                VARCHAR(40),
    kyc_status          VARCHAR(20),
    monthly_income_band VARCHAR(20)
);

-- Insert 22 active customers (matching user_ids from transactions table)
-- + 3 dormant customers (user_ids NOT in transactions)
INSERT INTO customers
  (customer_id, user_id, full_name, account_tier, signup_date, city, kyc_status, monthly_income_band)
VALUES
  ('CUS-001','USR-1106','Adaeze Okonkwo',   'Standard','2023-04-11','Abuja',         'Pending', '50k-100k'),
  ('CUS-002','USR-1409','Emeka Okafor',     'Standard','2022-06-07','Lagos',         'Verified','200k-500k'),
  ('CUS-003','USR-1520','Fatima Al-Hassan', 'Premium', '2022-07-19','Ibadan',        'Verified','500k+'),
  ('CUS-004','USR-2424','Chukwudi Eze',     'Standard','2021-09-12','Ibadan',        'Pending', '50k-100k'),
  ('CUS-005','USR-2535','Ngozi Adeyemi',    'VIP',     '2023-06-30','Kano',          'Verified','50k-100k'),
  ('CUS-006','USR-2679','Babatunde Oladele','Standard','2023-09-09','Abuja',         'Pending', '100k-200k'),
  ('CUS-007','USR-3286','Aisha Musa',       'VIP',     '2023-01-13','Ibadan',        'Verified','200k-500k'),
  ('CUS-008','USR-3547','Tunde Fashola',    'Standard','2022-09-23','Kano',          'Pending', 'Below 50k'),
  ('CUS-009','USR-3615','Obiageli Nwosu',   'Standard','2022-06-19','Ibadan',        'Verified','200k-500k'),
  ('CUS-010','USR-4257','Suleiman Garba',   'VIP',     '2022-12-01','Ibadan',        'Verified','Below 50k'),
  ('CUS-011','USR-4527','Chioma Obi',       'Standard','2023-06-04','Abuja',         'Verified','500k+'),
  ('CUS-012','USR-4582','Musa Aliyu',       'VIP',     '2023-11-09','Abuja',         'Verified','Below 50k'),
  ('CUS-013','USR-4811','Yetunde Balogun',  'Standard','2022-02-23','Port Harcourt', 'Verified','200k-500k'),
  ('CUS-014','USR-5012','Ifeanyi Chukwu',   'Standard','2022-11-07','Kano',          'Pending', 'Below 50k'),
  ('CUS-015','USR-5506','Zainab Umar',      'Standard','2021-09-17','Ibadan',        'Verified','50k-100k'),
  ('CUS-016','USR-5552','Kola Bello',       'VIP',     '2022-05-23','Abuja',         'Verified','100k-200k'),
  ('CUS-017','USR-6574','Amaka Osei',       'Standard','2023-10-06','Abuja',         'Verified','200k-500k'),
  ('CUS-018','USR-7873','Danladi Musa',     'Standard','2022-10-10','Ibadan',        'Verified','500k+'),
  ('CUS-019','USR-7912','Blessing Eze',     'Standard','2023-06-07','Lagos',         'Verified','100k-200k'),
  ('CUS-020','USR-7924','Taiwo Adekoya',    'VIP',     '2022-05-07','Port Harcourt', 'Verified','50k-100k'),
  ('CUS-021','USR-8359','Halima Yusuf',     'Standard','2023-08-04','Port Harcourt', 'Verified','100k-200k'),
  ('CUS-022','USR-9935','Uche Nnamdi',      'VIP',     '2022-07-07','Kano',          'Verified','Below 50k'),
  -- Dormant customers (not in transactions table)
  ('CUS-023','USR-9901','Kemi Adebayo',     'Standard','2023-06-15','Lagos',         'Verified','200k-500k'),
  ('CUS-024','USR-9902','Rotimi Akande',    'Premium', '2023-06-15','Lagos',         'Verified','200k-500k'),
  ('CUS-025','USR-9903','Hadiza Sule',      'VIP',     '2023-06-15','Lagos',         'Verified','200k-500k');

-- To Verify: SELECT COUNT(*) FROM customers;  → should return 25
