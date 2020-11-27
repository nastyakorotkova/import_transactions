create or replace package pkg_load_t is

  -- кол-во параллельных процессов
  c_load_processes integer := 10;
  c_api_processes  integer := 10;

  -- –азмер пачки за формирование справочника t_dict
  c_load_limit constant integer := 120;

  -- –азмер пачки на
  c_api_limit constant integer := 120;

  -- статусы
  c_status_new   constant integer := 0;
  c_status_done  constant integer := 1;
  c_status_error constant integer := 2;

  -- есть ли данные дл€ загрузки
  function askProcess(aTypeProcess integer) return integer;

  -- загрузка транзакций
  procedure runLoad;

  -- запуск API
  procedure runApi;

  -- логирование
  procedure writeLog(aTypeProcess integer,
                     akeyid       t_import.keyid%type,
                     aMsg         varchar2);

end pkg_load_t;
/
create or replace package body pkg_load_t is

  function askProcess(aTypeProcess integer) return integer is
    l_out integer := 0;
  begin
    if aTypeProcess = 1 then
      select 1
        into l_out
        from dual
       where exists (select 1 from t_import where state = c_status_new);
    elsif aTypeProcess = 2 then
      select 1
        into l_out
        from dual
       where exists (select 1 from t_dict where state = c_status_new);
    end if;
    return 1;
  exception
    when no_data_found then
      return 0;
  end;

  procedure runLoad is
  
    l_keyid  integer;
    l_exists integer;
  
    cursor cur_load_t is
      select keyid, dt, amount
        from t_import
       where state in (c_status_new, c_status_error)
         and rownum <= c_load_limit
         for update of state skip locked;
  
    l_cur_row cur_load_t%rowtype;
  
  begin
    open cur_load_t;
  
    loop
      exit when cur_load_t%notfound;
      fetch cur_load_t
        into l_cur_row;
      begin
      
        select count(1)
          into l_exists
          from t_dict
         where keyid = l_cur_row.keyid
           and dt = l_cur_row.dt
           and amount = l_cur_row.amount;
      
        if l_exists = 0 then
          update t_dict
             set dt     = l_cur_row.dt,
                 amount = l_cur_row.amount,
                 state  = c_status_new
           where keyid = l_cur_row.keyid
          returning keyid into l_keyid;
        
          if l_keyid is null then
            insert into t_dict
              (keyid, dt, amount)
            values
              (l_cur_row.keyid, l_cur_row.dt, l_cur_row.amount);
          end if;
        
          update t_import
             set state = c_status_done
           where keyid = l_cur_row.keyid;
        
          writelog(1, l_cur_row.keyid, 'create or update transaction');
        end if;
      exception
        when others then
          update t_import
             set state = c_status_error
           where keyid = l_cur_row.keyid;
        
          writeLog(1, l_cur_row.keyid, 'error ' || sqlerrm);
        
      end;
    end loop;
  
    close cur_load_t;
    commit;
  end;

  procedure runApi is
  
    cursor cur_load_t is
      select keyid, dt, amount
        from t_dict
       where state in (c_status_new, c_status_error)
         and rownum <= c_api_limit
         for update of state skip locked;
  
    l_cur_row cur_load_t%rowtype;
  begin
    open cur_load_t;
  
    loop
      exit when cur_load_t%notfound;
      fetch cur_load_t
        into l_cur_row;
      begin
      
        -- тут добавить запуск API
      
        update t_dict
           set state = c_status_done
         where keyid = l_cur_row.keyid;
      
        writelog(2, l_cur_row.keyid, 'start API');
      exception
        when others then
        
          update t_dict
             set state = c_status_error
           where keyid = l_cur_row.keyid;
        
          writeLog(2, l_cur_row.keyid, 'error ' || sqlerrm);
      end;
    end loop;
  
    close cur_load_t;
    commit;
  end;

  procedure writeLog(aTypeProcess integer,
                     akeyid       t_import.keyid%type,
                     aMsg         varchar2) is
    pragma AUTONOMOUS_TRANSACTION;
  begin
    insert into t_log
      (idlog, idtypeprocess, keyid, ts, msg)
    values
      (genid_t_log.nextval, aTypeProcess, akeyid, CURRENT_TIMESTAMP, aMsg);
    commit;
  end;

end pkg_load_t;
/
