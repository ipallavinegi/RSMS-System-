import nodemailer from "npm:nodemailer@6.9.13";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { userEmail, userName, password, role, username } = await req.json();

    if (!userEmail || !password) {
      throw new Error('userEmail and password are required fields');
    }

    // IF YOU WANT TO HARDCODE INSTEAD OF USING SECRETS:
    // Change these lines to:
    // const gmailEmail = "your.email@gmail.com";
    // const gmailAppPassword = "your-16-digit-password";
    const gmailEmail = "laviji95@gmail.com";
    const gmailAppPassword = "cdzl bvqh wiuv mtwc";

    if (!gmailEmail || !gmailAppPassword) {
      throw new Error('Server configuration error: Gmail credentials are not configured.');
    }

    const transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 465,
      secure: true, // use SSL
      auth: {
        user: gmailEmail,
        pass: gmailAppPassword,
      },
    });

    const mailOptions = {
      from: `"RSMS Admin" <${gmailEmail}>`,
      to: userEmail,
      subject: 'Welcome to RSMS - Your Login Credentials',
      text: `Hello ${userName},\n\nYour account has been created for the role of ${role}.\n\nYour login credentials are:\nUsername: ${username}\nPassword: ${password}\n\nPlease log into the app using this username and password.`,
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 8px;">
          <h2 style="color: #333;">Welcome to RSMS Admin!</h2>
          <p style="font-size: 16px; color: #555;">Hello ${userName},</p>
          <p style="font-size: 16px; color: #555;">An account has been created for you with the role of <strong>${role}</strong>.</p>
          <p style="font-size: 16px; color: #555;">Your temporary login credentials are:</p>
          <div style="background-color: #f5f5f5; padding: 12px 24px; font-size: 20px; font-weight: bold; letter-spacing: 1px; color: #0046c0; border-radius: 6px; display: inline-block; margin: 6px 0;">
            Username: ${username}
          </div>
          <br/>
          <div style="background-color: #f5f5f5; padding: 12px 24px; font-size: 20px; font-weight: bold; letter-spacing: 2px; color: #0046c0; border-radius: 6px; display: inline-block; margin: 6px 0;">
            Password: ${password}
          </div>
          <p style="font-size: 14px; color: #777;">Please log into the app using this username and password.</p>
        </div>
      `,
    };

    const info = await transporter.sendMail(mailOptions);

    return new Response(
      JSON.stringify({ success: true, message: 'Credentials email sent successfully', messageId: info.messageId }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});
