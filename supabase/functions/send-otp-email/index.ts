import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

serve(async (req) => {
  try {
    // 1. Get the payload from the iOS app
    const { email, otp, name } = await req.json();
    
    if (!email || !otp) {
      return new Response("Missing email or OTP", { status: 400 });
    }

    // 2. Send the email using Resend
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: "Admin Security <onboarding@resend.dev>", // Resend's free testing domain
        to: email, // The admin's email sent from the app
        subject: "Your RSMS Admin Login Code",
        html: `
          <h2>RSMS Admin Login</h2>
          <p>Hi ${name || 'Admin'},</p>
          <p>Your 6-digit verification code is:</p>
          <h1 style="letter-spacing: 5px;">${otp}</h1>
          <p>Please enter this code in the app to log in.</p>
        `,
      }),
    });

    const resendData = await res.json();
    return new Response(JSON.stringify(resendData), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
