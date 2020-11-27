declare
 vn integer := 0;
begin
  select count(1) into vn from dual where exists (select 1 from user_objects where object_type = 'TABLE' and object_name = 'T_LOG');
  if vn = 0 then
    execute immediate '   
    create table T_LOG
    (
      idlog         INTEGER not null,
      idtypeprocess INTEGER,
      keyid         INTEGER,
      ts            TIMESTAMP(6),
      msg           VARCHAR2(4000)
    )';

    execute immediate 'alter table T_LOG add constraint PK_IDLOG primary key (IDLOG)';
  end if;
end;
/
