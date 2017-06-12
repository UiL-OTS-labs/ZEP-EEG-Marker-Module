write_codes = true;
pulse_width = 10;

begin;

trial {
	LOOP $i 10;
	stimulus_event {
		nothing {};
		code = "marker$i";
		port_code = 1;
		deltat = 200;
	};
	ENDLOOP;
} main_trial;

trial main_trial;