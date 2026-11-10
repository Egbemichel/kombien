-- Local development seed: a handful of Yaoundé landmarks so search works
-- out of the box. Coordinates are APPROXIMATE and for development only;
-- the real landmark list is curated separately before launch.

insert into public.cities (name) values ('Yaoundé'), ('Douala');

insert into public.landmarks (city_id, name, aliases, location)
select c.id, l.name, l.aliases,
       extensions.st_setsrid(extensions.st_makepoint(l.lng, l.lat), 4326)::extensions.geography
from public.cities c,
     (values
       ('Poste Centrale',       array['Poste', 'Carrefour Poste'], 3.8666, 11.5167),
       ('Carrefour Warda',      array['Warda'],                    3.8740, 11.5140),
       ('Marché Mokolo',        array['Mokolo'],                   3.8770, 11.4990),
       ('Rond-point Nlongkak',  array['Nlongkak'],                 3.8840, 11.5210),
       ('Carrefour Bastos',     array['Bastos'],                   3.8950, 11.5090),
       ('Carrefour Mvan',       array['Mvan'],                     3.8270, 11.5160),
       ('Palais des Congrès',   array['Palais'],                   3.8860, 11.4950),
       ('Eyang',                array[]::text[],                   3.7860, 11.5450),
       ('Mvog-Mbi',             array['Mvog Mbi'],                 3.8550, 11.5260),
       ('Ngoa-Ekellé',          array['Ngoa Ekelle', 'Université'], 3.8600, 11.4990),
       ('Biyem-Assi',           array['Biyem Assi'],               3.8340, 11.4850),
       ('Essos',                array[]::text[],                   3.8700, 11.5380),
       ('Awae Escaliers',       array['Awae'],                     3.8790, 11.5550),
       ('Carrefour l''Amitié',  array['Amitié'],                   3.8890, 11.5300)
     ) as l(name, aliases, lat, lng)
where c.name = 'Yaoundé';
