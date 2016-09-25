<#
    .SYNOPSIS
    Formats a URL into Slack syntax for use in a message when posting to API
    
    .DESCRIPTION
    Formats a URL into Slack syntax for use in a message when posting to API
    
    .PARAMETER Url
    Mandatory
    The URL
  
    .PARAMETER Url
    Optional
    The display text for the hyperlink

    .EXAMPLE
    New-SlackMessageHyperlink -Url "https://www.google.co.uk" -DiplayText "Google"
    
    .OUTPUT
    The formatted url
    
    .NOTES
    Written by Martin Howlett @WillCode4Pizza
#>
Function New-SlackMessageHyperlink
{
    Param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter()][string]$DiplayText
    )

    $output = "<$Url"
    
    if($DiplayText)
    {
        write-output "<$Url|$DiplayText>"
    }
    else
    {
        write-output = "<$Url>"
    }
}

<#
    .SYNOPSIS
    Creates an attachement object used in Send-SlackMessage
    
    .DESCRIPTION
    Attachments let you add more context to a message, making them more useful and effective.
    This function generates them as a Powershell object so Send-SlackMessage can convert them

    .PARAMETER title
    Mandatory
    The title is displayed as larger, bold text near the top of a message attachment

    .PARAMETER text
    Mandatory
    This is the main text in a message attachment, and can contain standard message markup. 
    The content will automatically collapse if it contains 700+ characters or 5+ linebreaks, 
    and will display a "Show more..." link to expand the content.

    .PARAMETER type
    Mandatory
    Sets the colour of the attachment
    warning = yellow
    danger = red
    good = green
   
    .PARAMETER pretext
    Optional
    Optional text that appears above the attachment block
      
    .PARAMETER TitleLink
    Optional
    Add a hyperlink to the title
    Use New-SlackMessageHyperlink
    
    .PARAMETER fallback
    Mandatory
    Automatically set to title - text
    A plain-text summary of the attachment. This text will be used in clients that don't show 
    formatted text (eg. IRC, mobile notifications) and should not contain any markup.

    .EXAMPLE
    New-SlackMessageAttachment -title "Server SERVERNAME is at 4% disk space" -text "Drive C: has 1GB free" -type danger
    
    .OUTPUT
    PSobject of the attachmen
    
    .NOTES
    Written by Martin Howlett @WillCode4Pizza
#>
Function New-SlackMessageAttachment
{
    Param(
        [Parameter(Mandatory=$true)][string]$title,
        [Parameter(Mandatory=$true)][string]$text,
        [ValidateSet('warning','danger','good')]
        [Parameter(Mandatory=$true)][string]$type,
        [Parameter()][string]$pretext,
        [Parameter()][string]$TitleLink,
        [Parameter()][string]$fallback
    )
    
    #if fallback not provided set to to title - text
    if(-not $fallback)
    {
        $fallback = "$title - $text"
    }

    #create the object
    $AttachmentObject = @{              
            "fallback" ="$fallback"
            "title"= "$title"
            "text"= "$text"
            "color"= "$type"
    }

    #if title link, add it
    if ($TitleLink)
    {
       $AttachmentObject.Add("title_link",$TitleLink)
    }  
    
    #if pretext, add it
    if ($pretext)
    {
       $AttachmentObject.Add("pretext",$pretext)
    }  

    Return $AttachmentObject 
}

<#
    .SYNOPSIS
    Posts a message to a slack group from Powershell
    
    .DESCRIPTION
    Posts to a slack channel via the API 
    You will need a Slack token from https://my.slack.com/services/new/incoming-webhook/
    Notes on this method: https://api.slack.com/incoming-webhooks
        
    .PARAMETER Text
    Mandatory
    The text of your message
    
    For a new line:
    \n
    
    Hyperlink:
    Stuff in <> is a hyperlink, and use a pipe for the display name
    "<https://alert-system.com/alerts/1234|Click here> for details!"
    USe New-SlackMessageHyperlink for hyperlinks

    .PARAMETER SlackToken
    Mandatory
    Get it for your channel from https://my.slack.com/services/new/incoming-webhook/
    Must be in format "T000000000/B000000000/00000000000000000000000000"

    .PARAMETER channel
    Mandatory
    Channel you want to post in, will always start with #
    use @<username> to message a user
    
    .PARAMETER username
    The username of your bot
    Default is webhookbot

    .PARAMETER Icon
    The emoticon icon you want next to your username
    Default is grey_exclamation
    Check for supported icons here: http://www.emoji-cheat-sheet.com/
    Must be in format :NAME:

    .PARAMETER attachments
    Attachments are additional items attached to a message, which can have links, formatting etc
    See documentation here: https://api.slack.com/docs/attachments
    Use New-SlackMessageAttachment to generate them

    .EXAMPLE
    Send-SlackMessage -Text "Hello world" -ApiKey "0000000000/0000000000/00000000000000000000000000" -channel "#disk-alerts"
    
    .OUTPUT
    True/False
    
    .NOTES
    Written by Martin Howlett @WillCode4Pizza
#>
Function Send-SlackMessage
{
    Param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)][string]$ApiKey,
        [Parameter(Mandatory=$true)][string]$channel,
        [Parameter()][string]$username = "webhookbot",
        [Parameter()][string]$Icon = ":grey_exclamation:",
        [Parameter()][array]$Attachments
    )
    
    #add our key to the url
    $Url = "https://hooks.slack.com/services/$ApiKey"

    #create the start of the json body
    $JsonObject =  @{
        "text" = "$Text"
        "username" = "$username"
        "icon_emoji" = "$Icon"
        "channel" = "$channel"
    }

    #if the user has provided attachements, add them
    if($Attachments)
    {
        $JsonObject.Add("attachments",$Attachments)
    }

    #convert to json, this will escpase some special characters so unescape them again
    $Json = $($JsonObject | ConvertTo-Json | ForEach-Object{ [System.Text.RegularExpressions.Regex]::Unescape($_)})

    #slack likes this payload variable
    $Body = "payload=$Json"

    #post it
    $response = Invoke-RestMethod -Method POST -Uri $Url -Body "$Body"

    #ok returned on success
    if($response -eq "ok")
    {
        Write-Output $true
    }
    else
    {
        Write-Output $false
    }
}