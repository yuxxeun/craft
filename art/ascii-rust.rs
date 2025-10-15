use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();
    let prog = &args[0];
    if args.len() < 2 {
        print_usage(prog);
        return;
    }

    let path = &args[1];
    let mut width: u32 = 100;
    let mut invert = false;
    let mut chars = String::from(DEFAULT_CHARS);

    for a in &args[2..] {
        if a == "--invert" {
            invert = true;
        } else if a.starts_with("--chars=") {
            let v = a.trim_start_matches("--chars=");
            if !v.is_empty() {
                chars = v.to_string();
            }
        } else if let Ok(w) = a.parse::<u32>() {
            width = w;
        } else {
            eprintln!("Unknown argument: {}", a);
        }
    }

    if !Path::new(path).exists() {
        eprintln!("File not found: {}", path);
        return;
    }

    let img = match image::open(path) {
        Ok(i) => i,
        Err(e) => {
            eprintln!("Failed to open image: {}", e);
            return;
        }
    };

    let ascii = image_to_ascii(&img, width, &chars, invert);
    println!("{}", ascii);
}
