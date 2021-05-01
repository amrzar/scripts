
BEGIN { start = 0; incomment = 0;}

{
    if (start == 0)
    {
        if (incomment == 0)
        {
            if (/^\/\*/)
            {
                incomment = 1
            }
            else
            {
                print $0;
                start = 1;
            }
        }
        else
        {
            if (/\*\/[[:space:]]*$/)
            {
                start = 1;
            }
        }
    }
    else
    {
        print $0
    }
}