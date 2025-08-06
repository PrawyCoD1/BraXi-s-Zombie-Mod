
///////////////////////////////////////////////////////////////////////////////
// PROJECT: CoDaM (formerly MAM)
// PURPOSE: Common helper functions
// UPDATE HISTORY
//	1/23/2003	-- Hammer: started
//	1/31/2003	-- Hammer: additional function comments added
//	2/3/2003	-- Hammer: updated version
//	11/20/2003	-- Hammer: converted from MAM (need to fix comments)
///////////////////////////////////////////////////////////////////////////////

//
///////////////////////////////////////////////////////////////////////////////
main( phase )
{
	codam\utils::debug( 0, "======== utils/main:: |", phase, "|" );

	switch ( phase )
	{
	  case "init":		_init();		break;
	  case "load":		_load();		break;
	  case "start":	  	_start();		break;
	  case "standalone":	_standalone();		break;
	}

	return;
}

//
_init()
{
	codam\utils::debug( 0, "======== utils/_init" );

	// Identify current CoDaM version to the world
	level.codam_version = "1.31";
	setcvar( "codam_version", level.codam_version, true );

	__updateVars( true );

	// Useful for stats on mod usage and debugging ... can also be used
	// for intra-level feature management ...
	level.codam_session = getcvarint( "codam_session" ) + 1;
	setcvar( "codam_session", level.codam_session, true );
	_debug( "starting session #", level.codam_session );

	level.codam_credit = &"^2CoDaM^3 V";
	if ( isdefined( level.codam_enhanced ) )
		level.codam_credit = &"^2CoDaM ^5GT^3 V";
	return;
}

//
_load()
{
	codam\utils::debug( 0, "======== utils/_load" );

	if ( !isdefined( game[ "gamestarted" ] ) )
	{
		precacheString( level.codam_credit );
	}

	return;
}

//
_start()
{
	codam\utils::debug( 0, "======== utils/_start" );

	thread __updateVars();
	thread __showCredit();
	return;
}

//
_standalone()
{
	codam\utils::debug( 0, "======== utils/_standalone" );

	_init();
	_load();
	_start();
	return;
}

///////////////////////////////////////////////////////////////////////////////
//

//
///////////////////////////////////////////////////////////////////////////////
__updateVars( dontLoop )
{
	//////////////////////////////////////////////////////////////////////
	// Initialize some commonly used cvars: helps optimize code a bit ...
	level.ham_shortversion	= getcvar( "shortversion" );
	level.ham_arch		= getcvar( "arch" );
	level.ham_sv_maxclients	= getcvarint( "sv_maxclients" );
	level.ham_g_gametype	= toLower( getcvar( "g_gametype" ) );
	level.ham_mapname	= toLower( getcvar( "mapname" ) );
	//////////////////////////////////////////////////////////////////////

/*
	// Gametypes starting with c_ are CoDaMized
	_s = toLower( getcvar( "g_gametype" ) );
	if ( findStr( "c_", _s, "start" ) == 0 )
	{
		_a = "";
		for ( i = 2; i < _s.size; i++ )
			_a += _s[ i ];

		level.ham_g_gametype = _a;
	}
	else
		level.ham_g_gametype = _s;
*/

	for (;;)
	{
		if ( getcvar( "ham_developer" ) != "" )
			setcvar( "developer", getcvar( "ham_developer" ) );

		level.ham_debug = getcvarint( "ham_debug" );

		if ( isdefined( dontLoop ) )
			return;

		wait( 4 );
	}
}

//
///////////////////////////////////////////////////////////////////////////////
__showCredit()
{
	ver = newHudElem();
	ver.x = 1;
	ver.y = 474;
	ver.alignX = "left";
	ver.alignY = "middle";
	ver.sort = 99999;
	ver.fontScale = 0.6;
	ver.archived = true;
	ver.label = level.codam_credit;
	ver setValue( level.codam_version );

	return;
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Parse a string containing one or more "commands" separated by
//		semicolon.  Within a command, spaces will be used to separate
//		any arguments.  Arguments containing spaces may be optionally
//		treated as single arugments by including a quoting character.
// RETURN:	A 2-dim array; each command will occupy elements in the first
//		dim, while arguments within each command the 2nd.
// CALL:	<arr> = waitthread level.ham_f_utils::parseCmd <str> [<char>]
// EXAMPLE:	arr = waitthread level.ham_f_utils::parseCmd \
//				 "cmd1 \"This is 1\";cmd2 This is 2" "\""
//		arr == (cmd1::This is 1)::(cmd2::This::is::2)
// COMMENTS:	The string will first be passed through the dequote function
//
parseCmd( str, quote )
{
//	debug( 0, "parseCmd:: |", str, "|", quote, "|" );

	s = dequote( str );
	a = splitArray( s, "; ", quote, true );

	return ( a );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: Removes color changes in a string.
monotone( str )
{
//	debug( 98, "monotone:: |", str, "|" );

	if ( !isdefined( str ) || ( str == "" ) )
		return ( "" );

	_s = "";

	_colorCheck = false;
	for ( i = 0; i < str.size; i++ )
	{
		ch = str[ i ];
		if ( _colorCheck )
		{
			_colorCheck = false;

			switch ( ch )
			{
			  case "0":	// black
			  case "1":	// red
			  case "2":	// green
			  case "3":	// yellow
			  case "4":	// blue
			  case "5":	// cyan
			  case "6":	// pink
			  case "7":	// white
			  	break;
			  default:
			  	_s += ( "^" + ch );
			  	break;
			}
		}
		else
		if ( ch == "^" )
			_colorCheck = true;
		else
			_s += ch;
	}

//	codam\utils::debug( 99, "monotone = |", _s, "|" );

	return ( _s );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: Checks strings for color changes.
// RETURN: 0 if no color, 1 for color, 2> color open at end of string
hasColor( str )
{
//	debug( 98, "hasColor:: |", str, "|" );

	if ( !isdefined( str ) || ( str == "" ) )
		return ( 0 );

	_hasColor = 0;
	_lastColor = "7";
	_colorCheck = false;
	for ( i = 0; i < str.size; i++ )
	{
		ch = str[ i ];
		if ( _colorCheck )
		{
			_colorCheck = false;

			switch ( ch )
			{
			  case "0":	// black
			  case "1":	// red
			  case "2":	// green
			  case "3":	// yellow
			  case "4":	// blue
			  case "5":	// cyan
			  case "6":	// pink
			  case "7":	// white
			  	_hasColor = 1;
			  	_lastColor = ch;
			  	break;
			}
		}
		else
		if ( ch == "^" )
			_colorCheck = true;
	}

	if ( _colorCheck )
		_hasColor |= 2;		// Caret left open at end
	if ( _lastColor != "7" )
		_hasColor |= 4;		// Doens't end in white

//	debug( 99, "hasColor = |", _hasColor, "|" );

	return ( _hasColor );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	From an array of player status numbers and/or combination of
//		special team membership strings (all, allies, axis, spectator),
//		find all players matching.
// RETURN:	An array of $player index numbers matching the input criteria,
//		a string "all" when all players match, otherwise NIL
//		dim, while arguments within each command the 2nd.
// CALL:	<arr> = waitthread level.ham_f_utils::findPlayers <arr>
// EXAMPLE:	arr = waitthread level.ham_f_utils::findPlayers \
//						 1::2::0::all:axis::spectator
//		arr == "all"
//
//	- Assuming players 0-5 are axis, 6-10 are allies, 11-15 spectator
//		arr = waitthread level.ham_f_utils::findPlayers \
//					1::2::3::4::5::6::1::1::0::2::spectator
//			arr == 2::3::4::5::6::7::1::12::13::14::15::16
// COMMENTS:	Extraneous input criteria and/or invalid player status numbers
//		are silently ignored.  The function guarantees that only a
//		single instance of a player's index is returned.
//
playersFromList( idList )
{
//	debug( 98, "playersFromList" );

	if ( !isdefined( idList ) || ( idList.size < 1 ) )
		return ( undefined );

	statList = [];
	nameList = [];

	// Scan the input id list and keep track of valid requests ...
	for ( i = 0; i < idList.size; i++ )
	{
		id = idList[ i ];
		if ( isNumeric( id ) )
		{
			_id = (int) id;
			if ( ( _id >= 0 ) &&
			     ( _id < level.ham_sv_maxclients ) )
				statList[ _id ] = true;
		}
		else
		if ( id == "all" )
			return ( [] );
		else
			nameList[ id ] = true;
	}

//	dumpArray( 99, "statList", statList );

	pID = [];

	players = getentarray( "player", "classname" );
	for ( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		_team = player.sessionteam;
		if ( !isdefined( _team ) || ( _team == "none" ) )
			_team = player.pers[ "team" ];
		if ( !isdefined( _team ) )
			_team = "";

		_ent = player getEntityNumber();
		if ( isdefined( statList[ _ent ] ) ||
		     isdefined( nameList[ _team ] ) ||
		     isdefined( nameList[ monotone( player.name ) ] ) )
			pID[ pID.size ] = player;
	}

	// If no players match ...
	if ( pID.size < 1 )
		return ( undefined );

	// If somehow we end up with more players than allowed, return "all"
	if ( pID.size >= level.ham_sv_maxclients )
		return ( [] );

	return ( pID );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Determine player's from it's "status" id.  The
//		majority of external actions that can be applied to players
//		require some mechanism to identify each one.  Unfortunately,
//		the best available method is to perform a status command
//		from the console to determine the player's number.  This
//		number must be mapped to the internal entity for the player.
// RETURN:	The index (type int) into $player for the player, otherwise 0
// CALL:	<int> = waitthread level.ham_f_utils::playerId <int>
// EXAMPLE:	id = waitthread level.ham_f_utils::playerId 0
//		if ( id == 0 )
//			ignore_or_error
//		else
//			process_player_operation
//
playerFromId( id )
{
//	debug( 98, "playerFromId:: |", id, "|" );

	if ( !isdefined( id ) || ( id == "" ) )
		return ( undefined );

	ids = [];
	ids[ 0 ] = id;

	p = playersFromList( ids );

	if ( !isdefined( p ) || ( p.size != 1 ) )
		return ( undefined );

	return ( p[ 0 ] );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Send message to a player.
// RETURN:	None
// CALL:	waitthread level.ham_f_cmds::adminMsg <str>
// EXAMPLE:	waitthread level.ham_f_cmds::adminMsg "echo hello admin"
// COMMENTS:	Each command function should include at least one call to
//		this function.
//
playerMsg( id, msg, pri )
{
//	debug( 98, "playerMsg:: |", id, "|", msg, "|", pri, "|" );

	if ( !isdefined( msg ) || ( msg == "" ) )
		return;

	player = playerFromId( id );
	if ( !isdefined( player ) )
		return;

//	println( "Sending message to |", player.name, "^7|", msg, "^7|" );
	if ( isdefined( pri ) )
		player iprintlnbold( msg );
	else
		player iprintln( msg );

	return;
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Split the string into an n-dim array.  Each dim's entries are
//		determined by the separator characters.  A simple quoting
//		mechanism is provided to combine multiple arguments into one.
// RETURN:	An n-dim array
// CALL:	<arr> = waitthread level.ham_f_utils::splitArray \
//							<str> <str> [<char>]
// EXAMPLE:	arr = waitthread level.ham_f_utils::splitArray \
//				 ";," "cmd1 |1,2,3|;cmd2 1,2,3" "|"
//		arr == (cmd1::1,2,3)::(cmd2::1::2::3)
//
splitArray( str, sep, quote, skipEmpty )
{
//	debug( 98, "splitArray:: |", str, "|", sep, "|", quote, "|" );

	if ( !isdefined( str ) || ( str == "" ) )
		return ( [] );

	if ( !isdefined( sep ) || ( sep == "" ) )
		sep = ";";	// Default separator

	if ( !isdefined( quote ) )
		quote = "";

	skipEmpty = isdefined( skipEmpty );

	a = _splitRecur( 0, str, sep, quote, skipEmpty );

//	debug( 99, "splitArray size = " + a.size );

	return ( a );
}

//
///////////////////////////////////////////////////////////////////////////////
_splitRecur( iter, str, sep, quote, skipEmpty )
{
//	debug( 99, "_splitRecur #", iter, " |", str, "|", sep, "|", quote, "|",
//							skipEmpty, "|" );

	s = sep[ iter ];

	_a = [];
	_s = "";
	doQuote = false;
	for ( i = 0; i < str.size; i++ )
	{
		ch = str[ i ];
		if ( ch == quote )
		{
			doQuote = !doQuote;

			if ( iter + 1 < sep.size )
				_s += ch;
		}
		else
		if ( ( ch == s ) &&
		     !doQuote )
		{
			if ( ( _s != "" ) ||
			     !skipEmpty )
			{
				_l = _a.size;

				if ( iter + 1 < sep.size )
				{
					_x = _splitRecur( iter + 1, _s,
							sep, quote, skipEmpty );
					if ( ( _x.size > 0 ) ||
					     !skipEmpty )
					{
						_a[ _l ][ "str" ] = _s;
						_a[ _l ][ "fields" ] = _x;
					}
				}
				else
					_a[ _l ] = _s;
			}

			_s = "";
		}
		else
			_s += ch;
	}

	if ( _s != "" )
	{
		_l = _a.size;

		if ( iter + 1 < sep.size )
		{
			_x = _splitRecur( iter + 1, _s, sep, quote, skipEmpty );
			if ( _x.size > 0 )
			{
				_a[ _l ][ "str" ] = _s;
				_a[ _l ][ "fields" ] = _x;
			}
		}
		else
			_a[ _l ] = _s;
	}

//	debug( 99, "_splitRecur #", iter, " size = " + _a.size );

	return ( _a );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Find a string (find) within another string.  By default, the
//		find string can match anywhere, unless the third argument
//		is "start" or "end", in which case the match must be at the
//		beginning of the string or the end, respectively.
// RETURN:	Position (type int) where match occured or -1
// CALL:	<int> = waitthread level.ham_f_utils::findStr \
//							<str> <str> [<str>]
// EXAMPLE:	i = waitthread level.ham_f_utils::splitArray \
//						 "dm/" "dm/mohdm1" "start"
//		i == 0
// EXAMPLE:	i = waitthread level.ham_f_utils::splitArray \
//					"_tow" "obj/mp_flughafen_tow" "end"
//		i == 16
// EXAMPLE:	i = waitthread level.ham_f_utils::splitArray \
//					"blah" "obj/mp_flughafen_tow"
//		i == -1
//
findStr( find, str, pos )
{
//	debug( 98, "findStr:: |", find, "|", str, "|", pos, "|" );

	if ( !isdefined( find ) || ( find == "" ) ||
	     !isdefined( str ) ||
	     !isdefined( pos ) ||
	     ( find.size > str.size ) )
		return ( -1 );

	fsize = find.size;
	ssize = str.size;

	switch ( pos )
	{
	  case "start": place = 0 ; break;
	  case "end":	place = ssize - fsize; break;
	  default:	place = 0 ; break;
	}

	for ( i = place; i < ssize; i++ )
	{
		if ( i + fsize > ssize )
			break;			// Too late to compare

		// Compare now ...
		for ( j = 0; j < fsize; j++ )
			if ( str[ i + j ] != find[ j ] )
				break;		// No match

		if ( j >= fsize )
			return ( i );		// Found it!

		if ( pos == "start" )
			break;			// Didn't find at start
	}

	return ( -1 );
}

//
///////////////////////////////////////////////////////////////////////////////
// Convert uppercase characters in a string to lowercase
toLower( str )
{
	return ( mapChar( str, "U-L" ) );
}

//
///////////////////////////////////////////////////////////////////////////////
// Convert lowercase characters in a string to uppercase
toUpper( str )
{
	return ( mapChar( str, "L-U" ) );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Convert (map) characters in a string to another character.  A
//		conversion parameter determines how to perform the mapping.
// RETURN:	Mapped string
// CALL:	<str> = waitthread level.ham_f_utils::mapChar <str> <str>
//
mapChar( str, conv )
{
//	debug( 98, "mapChar:: |", str, "|", conv, "|" );

	if ( !isdefined( str ) || ( str == "" ) )
		return ( "" );

	switch ( conv )
	{
	  case "U-L":	case "U-l":	case "u-L":	case "u-l":
		from = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		to   = "abcdefghijklmnopqrstuvwxyz";
		break;
	  case "L-U":	case "L-u":	case "l-U":	case "l-u":
		from = "abcdefghijklmnopqrstuvwxyz";
		to   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		break;
	  default:
	  	return ( str );
	}

	s = "";
	for ( i = 0; i < str.size; i++ )
	{
		ch = str[ i ];

		for ( j = 0; j < from.size; j++ )
			if ( ch == from[ j ] )
			{
				ch = to[ j ];
				break;
			}

		s += ch;
	}

//	debug( 99, "mapChar = |", s, "|" );

	return ( s );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Determine if the argument (string) is completely numeric
// RETURN:	(bool) true, false
// CALL:	<bool> = level.ham_f_utils::isNumeric <str>
//
isNumeric( str )
{
//	debug( 98, "isNumeric:: |", str, "|" );

	if ( !isdefined( str ) || ( str == "" ) )
		return ( false );

	str += "";
	for ( i = 0; i < str.size; i++ )
		switch ( str[ i ] )
		{
		  case "0": case "1": case "2": case "3": case "4":
		  case "5": case "6": case "7": case "8": case "9":
		  	break;
		  default:
		  	return ( false );
		}

	return ( true );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Concatenate multiple similar cvars into a single string.
//		Cvars are limited to a maximum of 1024 characters in length.
//		Longer strings can be created by building "indexed" cvars:
//		_cvar_1 _cvar_2 _cvar_3 ... _cvar_# and placing the # into
//		the "count" cvar.  By default, cvars are separated by a space
//		unless the optional third argument is specified.
// RETURN:	String of concatenated cvars
// CALL:	<str> = waitthread level.ham_f_utils::cvarConcat \
//							<str> <str> [<str>]
// EXAMPLE:	s = waitthread level.ham_f_utils::cvarConcat "cc" "c"
//		with the following cvars:
//		set cc 2
//		set c1 "hello"
//		set c2 "world"
//
//		s == "hello world"
//
cvarConcat( prefix, label, options, sep )
{
//	debug( 98, "cvarConcat:: |", prefix, "|", cvar, "|", sep, "|" );

	if ( !isdefined( prefix ) )
		prefix = "";

	if ( !isdefined( label ) || ( label == "" ) )
		return ( "" );

	if ( !isdefined( sep ) )
		sep = " ";

//	count = getcvarint( cvarPrefix + "count" );
//	debug( 99, "cvarContact:: " + cvarPrefix + "count = " + count );

	s = "";
	count = 1;
	for (;;)
	{
		// HAM - need to do some bound checking to avoid infinite loop
		tmp_s = getVar( prefix, label + count, "string", options, "" );
		if ( tmp_s == "" )
			break;

		if ( s != "" )
			s += sep;
		s += tmp_s;
		count++;
	}
/*
	for ( m = 0; m < count; m++ )
	{
		tmp_s = getcvar( cvarPrefix + m );
		if ( tmp_s == "" )
			break;

//		debug( 99, "cvarContact:: " + cvarPrefix + m + " = |" +
//								tmp_s + "|" );

		if ( s != "" )
			s += sep;
		s += tmp_s;
	}
*/

//	debug( 99, "cvarConcat = |", s, "|" );

	return ( s );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Generate and randomize an array of indexes (integers 1:len-1)
// RETURN:	1-dim array of random indexes from 0 to len-1
// CALL:	<arr> = waitthread level.ham_f_utils::randomIndex <int>
// EXAMPLE:	a = waitthread level.ham_f_utils::randomIndex 10
//
//		a == 3::4::8::2::5::1::9::7::6::0
// COMMENT:	This makes it simple to randomize a list of strings without
//		having to perform expensive string copies.
//
randomIndex( len )
{
	debug( 98, "randomIndex:: |", len, "|" );

	if ( len < 1 )
		return ( undefined );

	// Initialize the index array
	for ( i = 0; i < len; i++ )
		t[ i ] = i;

	i = 0;
	for ( j = len; j > 1; j-- )
	{
		n = randomInt( j );
		a[ i ] = t[ n ];
		i++;

		for ( k = n + 1; k < len; k++ )
		{
			t[ n ] = t[ k ];
			n++;
		}
	}

	a[ i ] = t[ 0 ];

	dumpArray( 99, "randomIndex", a );

	return ( a );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Parse a string looking for special characters which might be
//		mistaken by something else and hide them.  By default the
//		backslash character is used for escaping, but this can be
//		changed by passing another character as quote.
//		Special characters include:
//			"		- the double quote character (")
//					- a single space
//			\		- backslash itself
//			\x		- where x is any other value, return x
// RETURN:	Dequoted string.
// CALL:	<str> = waitthread level.ham_f_utils::dequote <str> [<char>]
// EXAMPLE:	a = waitthread level.ham_f_utils::dequote \
//				"|this\sis\ a\ \test My Name is \qHammer\q|"
//
//		s == |this is a test My Name is "Hammer"|
//
// COMMENT:	This function is particularly useful to work around limitations
//		while working with remote strings, e.g. passed through rcon
//
enquote( str, quote )
{
//	debug( 98, "enquote:: |", str, "|", quote, "|" );

	if ( !isdefined( str ) || ( str == "" ) )
		return ( "" );

	if ( !isdefined( quote ) || ( quote == "" ) )
		quote = "\\";	// The default quote character

	s = "";
	for ( i = 0; i < str.size; i++ )
	{
		ch = str[ i ];
		if ( ch == quote )
			s += ( quote + quote );
		else
			switch ( ch )
			{
			  case " ":	s += ( quote + "s" );	break;
			  case "\"":	s += ( quote + "q" );	break;
			  case ";":	s += ( quote + ":" );	break;
			  default:	s += ch;		break;
			}
	}

//	debug( 99, "enquote = |", s, "|" );

	return ( s );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Parse a string looking for special escape sequences used to
//		hide certain characters which might be mistaken by something
//		else.  By default the backslash character is used for escaping,
//		but this can be changed by passing another character as quote.
//		Special characters include:
//			\q		- the double quote character (")
//			\s		- a single space
//			\\		- backslash itself
//			\x		- where x is any other value, return x
// RETURN:	Dequoted string.
// CALL:	<str> = waitthread level.ham_f_utils::dequote <str> [<char>]
// EXAMPLE:	a = waitthread level.ham_f_utils::dequote \
//				"|this\sis\ a\ \test My Name is \qHammer\q|"
//
//		s == |this is a test My Name is "Hammer"|
//
// COMMENT:	This function is particularly useful to work around limitations
//		while working with remote strings, e.g. passed through rcon
//
dequote( str, quote )
{
//	debug( 98, "dequote:: |", str, "|", quote, "|" );

	if ( !isdefined( str ) || ( str == "" ) )
		return ( "" );

	if ( !isdefined( quote ) || ( quote == "" ) )
		quote = "\\";	// The default quote character

	s = "";

	inQuote = false;
	for ( i = 0; i < str.size; i++ )
	{
		ch = str[ i ];
		if ( inQuote )
		{
			inQuote = false;
			switch ( ch )
			{
			  case "s":	s += " ";	break;
			  case "q":	s += "\"";	break;
			  case ":":	s += ";";	break;
			  default:	s += ch;	break;
			}
		}
		else
		if ( ch == quote )
			inQuote = true;
		else
			s += ch;
	}

//	debug( 99, "dequote = |", s, "|" );

	return ( s );
}

//
///////////////////////////////////////////////////////////////////////////////
// PURPOSE: 	Get a cvar value
// RETURN:	cvar value of the requested type
//
getVar( prefix, label, type, options, defValue,
		a0, a1, a2, a3, a4, a5, a6, a7, a8, a9 )
{
//	debug( 98, "getVar:: |", prefix, "|", label, "|", type, "|",
//						options, "|", defValue, "|",
//						a0, "|", a1, "|", a2, "|",
//						a3, "|", a4, "|", a5, "|" );

	if ( !isdefined( label ) || ( label == "" ) )
		return ( undefined );

	if ( !isdefined( type ) )
		type = "";
	if ( !isdefined( options ) )
		options = 0;
	if ( !isdefined( prefix ) )
		prefix = "";
	if ( ( prefix != "" ) &&
	     ( prefix[ prefix.size - 1 ] != "_" ) )
		prefix += "_";

	// Check gametype specific cvar
	if ( options & 1 )
		_gtype = level.ham_g_gametype + "_";
	else
		_gtype = "";

	// Check for map specific cvar
	if ( options & 2 )
		_map = "_" + level.ham_mapname;
	else
		_map = "";

/*
	vars = [];
	vars[ vars.size ] = prefix + _gtype + label + _map;
	vars[ vars.size ] = prefix + label + _map;
	vars[ vars.size ] = prefix + _gtype + label;
	vars[ vars.size ] = prefix + label;
*/

	val = "";
	if ( ( _gtype != "" ) && ( _map != "" ) )
	{
		var = prefix + _gtype + label + _map;
		val = getcvar( var );
	}
	if ( ( val == "" ) && ( _map != "" ) )
	{
		var = prefix + label + _map;
		val = getcvar( var );
	}
	if ( ( val == "" ) && ( _gtype != "" ) )
	{
		var = prefix + _gtype + label;
		val = getcvar( var );
	}
	if ( val == "" )
	{
		var = prefix + label;
		val = getcvar( var );
	}

/*
	varDone = [];
	for ( i = 0; i < vars.size; i++ )
	{
		var = vars[ i ];
		if ( !isdefined( varDone[ var ] ) )
		{
			val = getcvar( var );
			if ( val != "" )
				break;
			varDone[ var ] = true;
		}
	}
*/

	switch ( type )
	{
	  case "int":
		if ( val == "" )
			val = defValue;
		else
		{
		  	val = getcvarint( var );
			if ( isdefined( a0 ) && ( val < (int) a0 ) )
				val = (int) a0;
			else
			if ( isdefined( a1 ) && ( val > (int) a1 ) )
				val = (int) a1;
		}

		break;
	  case "float":
		if ( val == "" )
			val = defValue;
		else
		{
		  	val = getcvarfloat( var );
			if ( isdefined( a0 ) && ( val < (float) a0 ) )
				val = (float) a0;
			else
			if ( isdefined( a1 ) && ( val > (float) a1 ) )
				val = (float) a1;
		}

		break;
	  case "bool":
	  	switch ( toLower( val ) )
	  	{
	  	  case "":
			val = defValue;
	  	  	break;
	  	  case "true":
	  	  case "yes":
	  	  case "1":
	  	  	val = true;
	  	  	break;
	  	  default:
	  	  	val = false;
	  	  	break;
	  	}
		break;
	  case "list":
  		if ( isdefined( a0 ) && ( val == a0 ) ) break;
  		if ( isdefined( a1 ) && ( val == a1 ) ) break;
  		if ( isdefined( a2 ) && ( val == a2 ) ) break;
  		if ( isdefined( a3 ) && ( val == a3 ) ) break;
  		if ( isdefined( a4 ) && ( val == a4 ) ) break;
  		if ( isdefined( a5 ) && ( val == a5 ) ) break;
  		if ( isdefined( a6 ) && ( val == a6 ) ) break;
  		if ( isdefined( a7 ) && ( val == a7 ) ) break;
  		if ( isdefined( a8 ) && ( val == a8 ) ) break;
  		if ( isdefined( a9 ) && ( val == a9 ) ) break;
  		val = defValue;
		break;
	  default:	// By default, treat everything as a string
	  	if ( val == "" )
			val = defValue;
	  	break;
	}

//	debug( 99, "getVar = |", var, "|", val, "|" );
	return ( val );
}

//
///////////////////////////////////////////////////////////////////////////////
_db( s, p )
{
	if ( isdefined( s ) )
		return ( s );

	if ( !isdefined( p ) )
		return ( "" );

	return ( "^3U^7" );
}

_debug(	a01, a02, a03, a04, a05, a06, a07, a08, a09, a10,
	a11, a12, a13, a14, a15, a16, a17, a18, a19, a20,
	a21, a22, a23, a24, a25, a26, a27, a28, a29, a30 )
{
	a01 = _db( a01, a02 ); a02 = _db( a02, a03 ); a03 = _db( a03, a04 );
	a04 = _db( a04, a05 ); a05 = _db( a05, a06 ); a06 = _db( a06, a07 );
	a07 = _db( a07, a08 ); a08 = _db( a08, a09 ); a09 = _db( a09, a10 );
	a10 = _db( a10, a11 ); a11 = _db( a11, a12 ); a12 = _db( a12, a13 );
	a13 = _db( a13, a14 ); a14 = _db( a14, a15 ); a15 = _db( a15, a16 );
	a16 = _db( a16, a17 ); a17 = _db( a17, a18 ); a18 = _db( a18, a19 );
	a19 = _db( a19, a20 ); a20 = _db( a20, a21 ); a21 = _db( a21, a22 );
	a22 = _db( a22, a23 ); a23 = _db( a23, a24 ); a24 = _db( a24, a25 );
	a25 = _db( a25, a26 ); a26 = _db( a26, a27 ); a27 = _db( a27, a28 );
	a28 = _db( a28, a29 ); a29 = _db( a29, a30 ); a30 = _db( a30, a30 );

	session = level.codam_session;
	if ( !isdefined( session ) )
		session = "0";

	println( "^3------^2 CoDaM^7(", session, ", ", getTime(), "): ",
			a01, a02, a03, a04, a05, a06, a07, a08, a09, a10,
			a11, a12, a13, a14, a15, a16, a17, a18, a19, a20,
			a21, a22, a23, a24, a25, a26, a27, a28, a29, a30 );
	return;
}

//
///////////////////////////////////////////////////////////////////////////////
debug( debugLvl,
	a01, a02, a03, a04, a05, a06, a07, a08, a09, a10,
	a11, a12, a13, a14, a15, a16, a17, a18, a19, a20,
	a21, a22, a23, a24, a25, a26, a27, a28, a29, a30 )
{
	if ( !isdefined( level.ham_debug ) ||
	     !isdefined( debugLvl ) ||
	     ( debugLvl >= level.ham_debug ) )
		return;

	_debug(	a01, a02, a03, a04, a05, a06, a07, a08, a09, a10,
		a11, a12, a13, a14, a15, a16, a17, a18, a19, a20,
		a21, a22, a23, a24, a25, a26, a27, a28, a29, a30 );

	return;
}

//
///////////////////////////////////////////////////////////////////////////////
dumpArray( debugLvl, msg, a )
{
	if ( level.ham_debug > debugLvl )
	{
		s = msg + " = [ ";
		for ( i = 0; i < a.size; i++ )
		{
			if ( isdefined( a[ i ] ) )
				_t = a[ i ];
			else
				_t = "^3U^7";

			s += ( i + "=|" + _t + "| " );
		}
		s += "]";
		_debug( s );
	}

	return;
}

//
///////////////////////////////////////////////////////////////////////////////
