-- AM Revisor ESX SQL
-- Kør dette i din database, hvis jobbet/society ikke findes i forvejen.

INSERT IGNORE INTO jobs (name, label) VALUES
('revisor', 'Revisor');

INSERT IGNORE INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
('revisor', 0, 'trainee', 'Praktikant', 150, '{}', '{}'),
('revisor', 1, 'employee', 'Revisor', 250, '{}', '{}'),
('revisor', 2, 'boss', 'Chefrevisor', 400, '{}', '{}');

-- ESX Society / addonaccount
INSERT IGNORE INTO addon_account (name, label, shared) VALUES
('society_revisor', 'Revisor', 1);

INSERT IGNORE INTO addon_inventory (name, label, shared) VALUES
('society_revisor', 'Revisor', 1);

INSERT IGNORE INTO datastore (name, label, shared) VALUES
('society_revisor', 'Revisor', 1);
