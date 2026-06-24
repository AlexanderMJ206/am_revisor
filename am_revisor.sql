-- AM Revisor SQL
-- Kun nødvendig for ESX/QB/QBox database setup. vRP job/permissions laves typisk i vRP config.

-- ESX
INSERT IGNORE INTO jobs (name, label) VALUES
('revisor', 'Revisor');

INSERT IGNORE INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
('revisor', 0, 'trainee', 'Praktikant', 150, '{}', '{}'),
('revisor', 1, 'employee', 'Revisor', 250, '{}', '{}'),
('revisor', 2, 'boss', 'Chefrevisor', 400, '{}', '{}');

INSERT IGNORE INTO addon_account (name, label, shared) VALUES
('society_revisor', 'Revisor', 1);

INSERT IGNORE INTO addon_inventory (name, label, shared) VALUES
('society_revisor', 'Revisor', 1);

INSERT IGNORE INTO datastore (name, label, shared) VALUES
('society_revisor', 'Revisor', 1);

-- QB/QBox jobs skal normalt tilføjes i qb-core/shared/jobs.lua eller qbx_core config:
-- revisor = { label = 'Revisor', defaultDuty = true, grades = { ['0'] = { name = 'Medarbejder', payment = 150 }, ['1'] = { name = 'Revisor', payment = 250 }, ['2'] = { name = 'Chef', isboss = true, payment = 400 } } }
