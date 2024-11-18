
-- Geospatial-Functions
-- https://www.ibm.com/docs/en/i/7.5?topic=analytics-geospatial-functions
-- https://developers.google.com/maps/documentation/urls/get-started#map-action


-- First Add logitude and latitude to our organization table to have something to play with:
-- Note the data type: st_point
select * from sqlxxl.org;
alter table sqlxxl.org add column location_point qsys2.st_point;

begin
  update sqlxxl.org set location_point = qsys2.st_point('point(-74.1836766579507 40.72614325050191)'   ) where deptnumb = '10' ;
  update sqlxxl.org set location_point = qsys2.st_point('point(-71.0496584723428 42.34274735720927)'   ) where deptnumb = '15' ;
  update sqlxxl.org set location_point = qsys2.st_point('point(-77.04418137554369 38.89861126828182)'  ) where deptnumb = '20' ;
  update sqlxxl.org set location_point = qsys2.st_point('point(-84.38992100266495 33.76071296310947)'  ) where deptnumb = '38' ;
  update sqlxxl.org set location_point = qsys2.st_point('point(-87.63446953360999 41.8658379460295)'   ) where deptnumb = '42' ;
  update sqlxxl.org set location_point = qsys2.st_point('point(-96.82631994829717 32.81593973346066)'  ) where deptnumb = '51' ;
  update sqlxxl.org set location_point = qsys2.st_point('point(-122.41288137687724 37.75891424086738)' ) where deptnumb = '66' ;
  update sqlxxl.org set location_point = qsys2.st_point('point(-104.92721873373017 39.77002763801998)' ) where deptnumb = '84' ;
end;
select * from sqlxxl.org;

-- Create a global variable with my current location:
create or replace variable sqlxxl.my_location qsys2.st_point;
set sqlxxl.my_location = qsys2.st_point('point(12.491351574215194 55.90093990665238)');

-- The binary value - not that readable:
values sqlxxl.my_location;

-- Convert it to some readable text:
values qsys2.st_astext(sqlxxl.my_location);

-- Unwrangle the latitude/longitude cooridinate 
values qsys2.st_astext(sqlxxl.my_location);
values real(regexp_substr ( qsys2.st_astext(sqlxxl.my_location) ,'(POINT \()([0-9.-]*) ([0-9.-]*)',1,1,'c',2));
values real(regexp_substr ( qsys2.st_astext(sqlxxl.my_location) ,'(POINT \()([0-9.-]*) ([0-9.-]*)',1,1,'c',3));


-- Put this in a function to return a google map's link:
create or replace function sqlxxl.google_maps_link ( 
    geo_location qsys2.st_point
)
returns varchar(1024) 
modifies sql data
begin 
    declare latitude varchar (32);
    declare longitude varchar (32);
    declare reg varchar(256) default '(POINT \()([0-9.-]*) ([0-9.-]*)';
    declare point_text  varchar(256);

    set point_text = qsys2.st_astext(geo_location);
    set longitude  = regexp_substr (point_text, reg, 1, 1, 'c', 2);
    set latitude   = regexp_substr (point_text, reg, 1, 1, 'c', 3);

    return  'https://www.google.com/maps/search/?api=1&query='|| latitude ||',' || longitude;
    
end;

-- Does it work? 
values sqlxxl.google_maps_link(sqlxxl.my_location);


-- Now put up a link to all our branch offices:
select 
    deptnumb, 
    deptname, 
    division, 
    location,  
    qsys2.st_astext(location_point) point,  
    sqlxxl.google_maps_link (location_point) link  
from sqlxxl.org;

-- Caclulate distancs between all our brancheoffices
select 
    a.location , 
    b.location ,
    int(qsys2.st_distance (a.location_point , b.location_point) / 1000) distance_in_km
from sqlxxl.org a , sqlxxl.org b
-- where a.deptnumb < b.deptnumb
order by 
    a.location , 
    b.location 
;

