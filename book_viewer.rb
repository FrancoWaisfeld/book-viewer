require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

def each_chapter
  @contents.each_with_index do |chapter_name, index|
    chapter_number = index + 1
    contents = File.read("data/chp#{chapter_number}.txt")
    yield(chapter_name, chapter_number, contents)
  end
end

def found_in_chapters(query)
  result_chapters = []

  return if !query || query.empty?

  each_chapter do |chapter_name, chapter_number, contents|
    if contents.include?(query)
      result_chapters << {
        chapter_name: chapter_name,
        chapter_number: chapter_number
      }
    end
  end

  result_chapters
end

def found_in_paragraphs(query)
  result_paragraphs = []

  return if !query || query.empty?

  @result_chapters.each do |chapter|
    paragraphs =
    split_paragraphs(File.read("data/chp#{chapter[:chapter_number]}.txt"))

    paragraphs.each_with_index do |paragraph, index|
      if paragraph.include?(query)
        result_paragraphs << [paragraph, index + 1]
      end
    end
  end
  result_paragraphs
end

def split_paragraphs(content)
  content.split("\n\n")
end

def count_paragraphs(paragraphs)
  (1..paragraphs.size).to_a
end

helpers do
  def strong_query(paragraph)
    paragraph.sub(params[:query], "<strong>#{params[:query]}</strong>")
  end
end

helpers do
  def in_paragraphs(content)
    paragraphs = split_paragraphs(content)
    paragraphs_counter = count_paragraphs(paragraphs)


    paragraphs.zip(paragraphs_counter).map do |paragraph, count|
      "<p id=\"#{count}\">#{paragraph}</p>"
    end.join
  end
end

before do
  @contents = File.readlines("data/toc.txt")
end

not_found do
  redirect "/"
end

get "/" do
  @title = "The Adventures of Sherlock Homes"

  erb :home
end

get "/search" do
  @result_chapters = found_in_chapters(params[:query])
  @result_paragraphs = found_in_paragraphs(params[:query])
  erb :search
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]

  redirect "/" unless (1..@contents.size).cover?(number)

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end