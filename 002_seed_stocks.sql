-- ═══════════════════════════════════════════════════
--  WAMY — Seed Data: 78 sociétés cotées
--  Run after 001_initial_schema.sql
-- ═══════════════════════════════════════════════════

INSERT INTO public.stocks (ticker, name, sector, rank, domain, div, div_yield, div_freq, div_date)
VALUES
  -- BANQUES
  ('ATW',  'Attijariwafa Bank',    'banques',        1,  'attijariwafabank.ma',    34.5,  4.99, 'Annuel', 'Mai 2025'),
  ('BOA',  'Bank Of Africa',       'banques',        2,  'bankofafrica.ma',         9.0,  4.10, 'Annuel', 'Mai 2025'),
  ('BCP',  'BCP',                  'banques',        3,  'gbp.ma',                 12.0,  4.74, 'Annuel', 'Mai 2025'),
  ('BMCI', 'BMCI',                 'banques',        4,  'bmci.ma',                32.0,  5.00, 'Annuel', 'Juin 2025'),
  ('CFG',  'CFG Bank',             'banques',        5,  'cfg.ma',                  0.8,  2.81, 'Annuel', 'Juin 2025'),
  ('CIH',  'CIH Bank',             'banques',        6,  'cihbank.ma',             17.0,  4.78, 'Annuel', 'Mai 2025'),
  ('CDM',  'Crédit du Maroc',      'banques',        7,  'creditdumaroc.ma',       27.0,  4.66, 'Annuel', 'Juin 2025'),
  ('SLF',  'Salafin',              'banques',        8,  'salafin.ma',             19.0,  4.97, 'Annuel', 'Mai 2025'),
  -- ASSURANCES
  ('AFM',  'AFMA SA',              'assurances',     9,  'afma.ma',                55.0,  4.07, 'Annuel', 'Juin 2025'),
  ('AGM',  'Agma Lahlou-Tazi',     'assurances',    10,  'agma.ma',               200.0,  4.71, 'Annuel', 'Juin 2025'),
  ('ATL',  'AtlantaSanad',         'assurances',    11,  'atlantasanad.ma',         6.0,  4.29, 'Annuel', 'Juin 2025'),
  ('SAH',  'Sanlam Maroc',         'assurances',    12,  'sanlam.ma',              48.0,  4.29, 'Annuel', 'Juin 2025'),
  ('WAA',  'Wafa Assurance',       'assurances',    13,  'wafaassurance.ma',      210.0,  5.00, 'Annuel', 'Juin 2025'),
  -- MINES
  ('MNG',  'Managem',              'mines',         14,  'managemgroup.com',      200.0,  2.53, 'Annuel', 'Juin 2025'),
  ('CMT',  'Minière Touissit',     'mines',         15,  'cmtmaroc.ma',            75.0,  4.08, 'Annuel', 'Juin 2025'),
  ('SMI',  'Smi',                  'mines',         16,  'smi.ma',                 90.0,  4.00, 'Annuel', 'Juin 2025'),
  ('SID',  'Sonasid',              'mines',         17,  'sonasid.ma',             15.0,  3.93, 'Annuel', 'Juin 2025'),
  ('DHO',  'Delta Holding',        'mines',         18,  'deltaholding.ma',         1.2,  3.35, 'Annuel', 'Juin 2025'),
  ('ZDJ',  'Zellidja S.A.',        'mines',         19,  'zellidja.ma',            12.0,  3.69, 'Annuel', 'Juin 2025'),
  -- BATIMENT
  ('CMA',  'Ciments du Maroc',     'batiment',      20,  'cimentsdumaroc.com',     85.0,  4.91, 'Annuel', 'Mai 2025'),
  ('LHM',  'LafargeHolcim Maroc',  'batiment',      21,  'lafargeholcim.ma',       90.0,  5.14, 'Annuel', 'Juin 2025'),
  ('GTM',  'SGTM',                 'batiment',      22,  'sgtm.ma',                28.0,  3.89, 'Annuel', 'Juil 2025'),
  ('TGC',  'TGCC',                 'batiment',      23,  'tgcc.ma',                22.0,  3.06, 'Annuel', 'Juil 2025'),
  ('COL',  'Colorado',             'batiment',      24,  'colorado.ma',             2.5,  4.03, 'Annuel', 'Juil 2025'),
  ('AFI',  'Afric Industries',     'batiment',      25,  'africindustries.ma',     14.0,  3.59, 'Annuel', 'Juin 2025'),
  ('JET',  'Jet Contractors',      'batiment',      26,  'jetcontractors.ma',      10.0,  3.51, 'Annuel', 'Juil 2025'),
  ('DLM',  'Delattre Levivier',    'batiment',      27,  'dlm.ma',                  4.5,  3.75, 'Annuel', 'Juin 2025'),
  -- ENERGIE
  ('TQM',  'Taqa Morocco',         'energie',       28,  'taqamorocco.ma',        113.0,  6.16, 'Annuel', 'Juin 2025'),
  ('TMA',  'TotalEnergies Maroc',  'energie',       29,  'totalenergies.ma',       82.0,  4.43, 'Annuel', 'Juin 2025'),
  ('MOX',  'Maghreb Oxygène',      'energie',       30,  'maghreboxy.ma',          24.0,  3.87, 'Annuel', 'Juin 2025'),
  ('GAZ',  'Afriquia Gaz',         'energie',       31,  'afriquiagaz.ma',        180.0,  4.17, 'Annuel', 'Juin 2025'),
  -- TELECOM
  ('IAM',  'Maroc Telecom',        'telecom',       32,  'iam.ma',                  6.38, 6.77, 'Annuel', 'Juin 2025'),
  ('HPS',  'HPS',                  'telecom',       33,  'hps-worldwide.com',     175.0,  2.68, 'Annuel', 'Juin 2025'),
  ('INV',  'Involys',              'telecom',       34,  'involys.com',             2.0,  3.54, 'Annuel', 'Juil 2025'),
  ('M2M',  'M2M Group',            'telecom',       35,  'm2mgroup.com',           24.0,  3.08, 'Annuel', 'Juin 2025'),
  ('DYT',  'Disty Technologies',   'telecom',       36,  'disty.ma',                6.0,  3.33, 'Annuel', 'Juin 2025'),
  ('DWY',  'Disway',               'telecom',       37,  'disway.ma',              15.0,  3.57, 'Annuel', 'Juin 2025'),
  ('IBC',  'IB Maroc.com',         'telecom',       38,  'ibmaroc.com',             1.5,  3.53, 'Annuel', 'Juil 2025'),
  ('MIC',  'Microdata',            'telecom',       39,  'microdata.ma',           12.0,  3.43, 'Annuel', 'Juin 2025'),
  ('SMM',  'S.M. Monétique',       'telecom',       40,  'sm-monetique.com',       50.0,  4.00, 'Annuel', 'Juin 2025'),
  ('CAP',  'Cash Plus',            'telecom',       41,  'cashplus.ma',            14.0,  3.89, 'Annuel', 'Juin 2025'),
  -- AGROALIMENTAIRE
  ('CSR',  'Cosumar',              'agroalimentaire',42, 'cosumar.ma',              9.5,  5.05, 'Annuel', 'Juin 2025'),
  ('LBV',  'Label Vie',            'agroalimentaire',43, 'labelvie.ma',           180.0,  3.33, 'Annuel', 'Juil 2025'),
  ('LES',  'Lesieur Cristal',      'agroalimentaire',44, 'lesieurchristal.ma',      7.5,  4.55, 'Annuel', 'Juin 2025'),
  ('MUT',  'Mutandis',             'agroalimentaire',45, 'mutandis.ma',             4.5,  3.66, 'Annuel', 'Juin 2025'),
  ('OUL',  'Oulmès',               'agroalimentaire',46, 'oulmes.ma',              85.0,  3.62, 'Annuel', 'Juin 2025'),
  ('CRS',  'Cartier Saada',        'agroalimentaire',47, 'cartier-saada.ma',        1.5,  3.13, 'Annuel', 'Juil 2025'),
  ('DRI',  'Dari Couspate',        'agroalimentaire',48, 'dari-couspate.com',      110.0, 3.49, 'Annuel', 'Juin 2025'),
  ('UMR',  'Unimer',               'agroalimentaire',49, 'unimer.ma',               2.5,  3.33, 'Annuel', 'Juin 2025'),
  ('SBM',  'SBM',                  'agroalimentaire',50, 'sbm.ma',                 80.0,  3.72, 'Annuel', 'Juin 2025'),
  -- TRANSPORT
  ('MSA',  'Marsa Maroc',          'transport',     51,  'marsamaroc.ma',          46.0,  5.94, 'Annuel', 'Juin 2025'),
  ('CTM',  'CTM',                  'transport',     52,  'ctm.ma',                 55.0,  3.57, 'Annuel', 'Juin 2025'),
  ('TIM',  'Timar',                'transport',     53,  'timar.ma',               14.0,  3.64, 'Annuel', 'Juin 2025'),
  -- IMMOBILIER
  ('ADH',  'Addoha',               'immobilier',    54,  'addoha.ma',               0.5,  2.70, 'Annuel', 'Juil 2025'),
  ('ADI',  'Alliances Immobilier', 'immobilier',    55,  'alliancesdeveloppement.ma',1.5, 3.32, 'Annuel', 'Juil 2025'),
  ('ARD',  'Aradei Capital',       'immobilier',    56,  'aradeicapital.com',      20.0,  4.17, 'Annuel', 'Juin 2025'),
  ('BAL',  'Balima',               'immobilier',    57,  'balima.ma',               6.0,  4.05, 'Annuel', 'Juin 2025'),
  ('IMO',  'Immorente Invest',     'immobilier',    58,  'immorente.ma',            4.5,  4.29, 'Annuel', 'Juin 2025'),
  ('RDS',  'Résidences Dar Saada', 'immobilier',    59,  'darsaada.ma',             1.2,  3.12, 'Annuel', 'Juil 2025'),
  -- DISTRIBUTION
  ('ATH',  'Auto Hall',            'distribution',  60,  'autohall.ma',             3.5,  4.49, 'Annuel', 'Juin 2025'),
  ('NEJ',  'Auto Nejma',           'distribution',  61,  'autonejmavw.com',        70.0,  3.85, 'Annuel', 'Juin 2025'),
  ('NKL',  'Ennakl Automobiles',   'distribution',  62,  'ennakl.com.tn',           5.5,  3.93, 'Annuel', 'Juin 2025'),
  -- INDUSTRIE
  ('SNP',  'Snep',                 'industrie',     63,  'snep.ma',                35.0,  3.98, 'Annuel', 'Juin 2025'),
  ('ALM',  'Aluminium du Maroc',   'industrie',     64,  'aluminium-maroc.com',    60.0,  3.85, 'Annuel', 'Juin 2025'),
  ('FBR',  'Fenie Brossette',      'industrie',     65,  'feniebrossette.ma',      12.0,  3.87, 'Annuel', 'Juin 2025'),
  ('MDP',  'Med Paper',            'industrie',     66,  'medpaper.ma',             2.0,  3.45, 'Annuel', 'Juil 2025'),
  ('MAB',  'Maghrebail',           'industrie',     67,  'maghrebail.ma',          17.0,  3.95, 'Annuel', 'Juin 2025'),
  ('MLE',  'Maroc Leasing',        'industrie',     68,  'marocleasing.ma',        10.0,  3.77, 'Annuel', 'Juin 2025'),
  ('SRM',  'Réalisations Méca.',   'industrie',     69,  'srm.ma',                 75.0,  3.87, 'Annuel', 'Juin 2025'),
  -- SANTE
  ('AKT',  'Akdital',              'sante',         70,  'akdital.ma',              8.0,  1.67, 'Annuel', 'Juin 2025'),
  ('PRO',  'Promopharm',           'sante',         71,  'promopharm.ma',          55.0,  3.79, 'Annuel', 'Juin 2025'),
  ('SOT',  'Sothema',              'sante',         72,  'sothema.com',            90.0,  4.00, 'Annuel', 'Juin 2025'),
  -- HOLDING
  ('ALM2', 'Al Mada',              'holding',       73,  'almada.ma',              70.0,  3.33, 'Annuel', 'Juin 2025'),
  ('EQD',  'Eqdom',                'holding',       74,  'eqdom.ma',               40.0,  4.17, 'Annuel', 'Juin 2025'),
  ('REB',  'Rebab Company',        'holding',       75,  'rebab.ma',                0.8,  3.27, 'Annuel', 'Juil 2025'),
  ('RIS',  'Risma',                'holding',       76,  'risma.ma',                5.0,  2.86, 'Annuel', 'Juin 2025'),
  ('VAL',  'Valoris',              'holding',       77,  'valoris.ma',              6.0,  3.70, 'Annuel', 'Juin 2025'),
  -- SUSPENDU
  ('SAM',  'Samir (Suspendu)',      'energie',       78,  'samir.ma',               0.0,  0.00, '—',      'Suspendu')
ON CONFLICT (ticker) DO UPDATE SET
  name      = EXCLUDED.name,
  sector    = EXCLUDED.sector,
  rank      = EXCLUDED.rank,
  domain    = EXCLUDED.domain,
  div       = EXCLUDED.div,
  div_yield = EXCLUDED.div_yield,
  div_freq  = EXCLUDED.div_freq,
  div_date  = EXCLUDED.div_date;
