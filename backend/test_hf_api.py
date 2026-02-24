from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline

model_name = "Salesforce/codegen-350M-mono"  # Or try: bigcode/starcoder2-1b
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name)

generator = pipeline("text-generation", model=model, tokenizer=tokenizer)

prompt = "Write a Python script that reads a file and prints its content."
output = generator(prompt, max_length=100, do_sample=True, temperature=0.7)

print(output[0]["generated_text"])
