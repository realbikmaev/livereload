## what is this?

Terraform template that deploys live reload server on [fly.io](https://fly.io/)

## why do I need this?

Imagine a situation: you're developing an frontend application, you hit deploy, open preview on your iPhone, and... CSS is all fucked up!

Desktop browser emulation of mobile devices just sucks.

Introducing:

✨ _dev servers on the edge_ ✨

## any alternatives?

Sure!

-   [cloudflare tunnels](https://developers.cloudflare.com/pages/how-to/preview-with-cloudflare-tunnel): great docs, easy to setup.
-   [localtunnel](https://github.com/localtunnel/localtunnel): open-source!
-   [ngrok](https://ngrok.com/): tbh never used it...

## if there are altenatives...

Why bother rolling out your own thing? I just felt like doing this.

## how do i use this?

```bash
# 1. rename the config
mv terraform.tfvars.example terraform.tfvars

# 2. open terraform.tfvars

# 3. fill in your own values

# 4. deploy
terraform init
terraform plan -out=terraform.tfplan
terraform apply terraform.tfplan

# 5.1 ssh into the server
ssh {vm_user}@{app_name}.fly.dev

# 5.2 (optional) install your dotfiles

# 6. git clone your project

# 7. run the server
npm run dev

# 8. open the url on your iPhone
```

## credits

Rust module shamelessly stolen from [here](https://fasterthanli.me/articles/remote-development-with-rust-on-fly-io).

Terraform code was revealed to me in a dream...
