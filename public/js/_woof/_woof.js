function toggleVisibility( id )
{
    /* Copied from Rails */
    var elem
    
    if( document.getElementById )
    {
        elem = document.getElementById( id )
    }
    else if ( document.all )
    {
        elem = eval( "document.all." + id )
    }
    else
        return false;
    
    if( elem.style.display == "block" )
    {
        elem.style.display = "none"
    }
    else
    {
        elem.style.display = "block"
    }
}

function wfAddClass(id, cls)
{
    document.getElementById(id).classList.add(cls)
}

function wfRemoveClass(id, cls)
{
    document.getElementById(id).classList.remove(cls)
}

function wfHasClass(id, cls)
{
    document.getElementById(id).classList.contains(cls)
}

function wfToggleClass(id, cls)
{
    document.getElementById(id).classList.toggle(cls)
}
